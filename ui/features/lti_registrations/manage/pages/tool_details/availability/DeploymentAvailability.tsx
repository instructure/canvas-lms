/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import * as React from 'react'
import {showFlashAlert, showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {confirm} from '@canvas/instui-bindings/react/Confirm'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Link as RouterLink} from 'react-router-dom'
import {createContextControls} from '../../../api/contextControls'
import {deleteDeployment} from '../../../api/deployments'
import {AccountId, ZAccountId} from '../../../model/AccountId'
import {ZCourseId} from '../../../model/CourseId'
import {LtiDeployment} from '../../../model/LtiDeployment'
import {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {askForContextControl} from './AskForContextControl'
import {ContextCard} from './ContextCard'
import {LtiContextControl} from '../../../model/LtiContextControl'
import {renderExceptionCounts} from './renderExceptionCounts'
import {List} from '@instructure/ui-list'
import {ExceptionModal, ExceptionModalOpenState} from './exception_modal/ExceptionModal'
import {formatApiResultError} from '../../../../common/lib/apiResult/ApiResult'

const I18n = createI18nScope('lti_registrations')

export type DeploymentAvailabilityProps = {
  accountId: AccountId
  deployment: LtiDeployment
  registration: LtiRegistrationWithAllInformation
  refetchControls: () => void
  debug: boolean
}

const contextIsForDeployment = (deployment: LtiDeployment) => (cc: LtiContextControl) => {
  return (
    (deployment.context_type === 'Course' && deployment.context_id === cc.course_id) ||
    (deployment.context_type === 'Account' && deployment.context_id === cc.account_id)
  )
}

export const DeploymentAvailability = (props: DeploymentAvailabilityProps) => {
  const {registration, deployment, debug, refetchControls} = props

  const controls_with_ids = deployment.context_controls
    .filter(cc => {
      // We don't want to show controls that are for the same context as the deployment
      return !contextIsForDeployment(deployment)(cc)
    })
    .map(cc => {
      if (cc.course_id) {
        return {
          path_id: `c${cc.course_id}`,
          control: cc,
        }
      } else {
        return {
          path_id: `a${cc.account_id}`,
          control: cc,
        }
      }
    })

  const rootControl = deployment.context_controls.find(contextIsForDeployment(deployment))

  const [exceptionModalOpenState, setExceptionModalOpenState] =
    React.useState<ExceptionModalOpenState>({
      open: false,
    })

  return (
    <View
      borderRadius="medium"
      borderColor="secondary"
      borderWidth="small"
      padding="medium"
      as="div"
    >
      <Heading level="h3">
        <Flex alignItems="center" justifyItems="space-between" as="div">
          <Flex.Item as="div">
            <Flex alignItems="center" as="div">
              <Flex.Item padding="0 xx-small 0 0" as="div">
                {I18n.t('Installed in %{context_name}', {
                  context_name: deployment.context_name,
                })}
              </Flex.Item>
              <Flex as="div">
                <Pill color="primary">
                  {rootControl?.available ? I18n.t('Available') : I18n.t('Unavailable')}
                </Pill>
              </Flex>
            </Flex>
          </Flex.Item>
          <Flex.Item as="div">
            <Button
              onClick={() => {
                setExceptionModalOpenState({
                  open: true,
                  deployment,
                })
              }}
              color="primary"
            >
              {I18n.t('Add Exception')}
            </Button>
          </Flex.Item>
          <ExceptionModal
            accountId={props.accountId}
            openState={exceptionModalOpenState}
            onClose={() => setExceptionModalOpenState({open: false})}
            onConfirm={contextControls => {
              const onError = showFlashError(
                I18n.t('There was an error adding the exceptions. Please try again later.'),
              )
              return createContextControls({
                registrationId: deployment.registration_id,
                contextControls,
              })
                .then(result => {
                  if (result._type === 'Success') {
                    showFlashSuccess(
                      I18n.t('%{count} exception(s) were successfully added.', {
                        count: contextControls.length,
                      }),
                    )()
                    refetchControls()
                  } else {
                    // handle error
                    console.error(formatApiResultError(result))
                    onError()
                  }
                })
                .catch(onError)
            }}
          />
        </Flex>
      </Heading>
      <div>
        <Text size="small">
          {I18n.t('Deployment ID: %{deployment_id}', {
            deployment_id: deployment.deployment_id,
          })}
        </Text>
      </div>
      <div>
        <Text size="small">{rootControl ? renderExceptionCounts(rootControl) : undefined}</Text>
      </div>
      <View as="div" margin="0 0 small">
        <Text>
          <Link to={`/manage/${registration.id}/configuration#placements`} as={RouterLink}>
            {I18n.t(
              {
                one: '1 placement',
                other: '%{count} placements',
              },
              {
                count: registration.overlaid_configuration.placements.filter(
                  p => p.enabled === undefined || p.enabled,
                ).length,
              },
            )}
          </Link>
        </Text>
      </View>
      <List itemSpacing="small" isUnstyled margin="0">
        {controls_with_ids.map(({control}) => {
          /**
           * This is the path of the control, where
           * each node is a realized control from the
           * path string id segments.
           */
          const controlPath = control.path
            .split('.')
            .filter(s => s.length > 0)
            .flatMap(s => {
              const matched = controls_with_ids.find(c => c.path_id === s)
              if (matched) {
                return [matched]
              } else {
                return []
              }
            })

          const closestParent = controlPath[controlPath.length - 2]
          return (
            <List.Item key={control.id} as="div">
              <ContextCard
                key={control.id}
                course_id={control.course_id ?? undefined}
                account_id={control.account_id ?? undefined}
                context_name={control.context_name}
                available={control.available}
                path_segments={control.display_path}
                depth={control.depth - 1}
                exception_counts={{
                  child_control_count: control.child_control_count,
                  course_count: control.course_count,
                  subaccount_count: control.subaccount_count,
                }}
                path={control.path}
                inherit_note={
                  closestParent && closestParent.control.available === control.available
                }
              />
            </List.Item>
          )
        })}
      </List>
      {
        /**
         * These are debug buttons, and will be removed before release
         */
        debug && (
          <>
            <Button
              onClick={() => {
                askForContextControl({
                  title: 'Create Control',
                }).then(([contextId, isCourse]) => {
                  createContextControls({
                    registrationId: registration.id,
                    contextControls: [
                      Object.assign(
                        {},
                        {
                          available: true,
                          deployment_id: deployment.id,
                        },
                        isCourse
                          ? {
                              course_id: ZCourseId.parse(contextId),
                            }
                          : {
                              account_id: ZAccountId.parse(contextId),
                            },
                      ),
                    ],
                  })
                })
              }}
            >
              Create Control
            </Button>
            <Button
              onClick={() => {
                confirm({
                  title: 'Delete Deployment',
                  message: 'Are you sure you want to delete this deployment?',
                  confirmButtonLabel: 'Delete',
                  cancelButtonLabel: 'Cancel',
                }).then(confirmed => {
                  if (confirmed) {
                    // Call the API to delete the deployment
                    deleteDeployment({
                      registrationId: registration.id,
                      accountId: registration.account_id,
                      deploymentId: deployment.id,
                    }).then(result => {
                      if (result._type === 'Success') {
                        // Handle success (e.g., show a success message or refresh the deployments)
                        refetchControls()
                      } else {
                        showFlashAlert({
                          type: 'error',
                          message: I18n.t('There was an error when deleting the deployment.'),
                        })
                      }
                    })
                  }
                })
              }}
            >
              Delete Deployment
            </Button>
          </>
        )
      }
    </View>
  )
}
