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
import {showFlashAlert, showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {confirm} from '@canvas/instui-bindings/react/Confirm'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import * as React from 'react'
import {Link as RouterLink} from 'react-router-dom'
import {
  isSuccessful,
  isUnsuccessful,
  formatApiResultError,
} from '../../../../common/lib/apiResult/ApiResult'
import {
  createContextControls,
  DeleteContextControl,
  UpdateContextControl,
} from '../../../api/contextControls'
import {deleteDeployment} from '../../../api/deployments'
import {AccountId, ZAccountId} from '../../../model/AccountId'
import {ZCourseId} from '../../../model/CourseId'
import {LtiContextControl, LtiContextControlId} from '../../../model/LtiContextControl'
import {LtiDeployment} from '../../../model/LtiDeployment'
import {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {askForContextControl} from './AskForContextControl'
import {ContextCard} from './ContextCard'
import {
  DeleteExceptionModal,
  DeleteExceptionModalOpenState,
} from './exception_modal/DeleteExceptionModal'

import {EditExceptionModal} from './exception_modal/EditExceptionModal'
import {ExceptionModal, ExceptionModalOpenState} from './exception_modal/ExceptionModal'
import {renderExceptionCounts} from './renderExceptionCounts'
const I18n = createI18nScope('lti_registrations')

export type DeploymentAvailabilityProps = {
  accountId: AccountId
  deployment: LtiDeployment
  registration: LtiRegistrationWithAllInformation
  deleteControl: DeleteContextControl
  editControl: UpdateContextControl
  refetchControls: () => void
  debug: boolean
}

const matchesDeploymentsContext = (deployment: LtiDeployment) => (cc: LtiContextControl) => {
  return (
    (deployment.context_type === 'Course' && deployment.context_id === cc.course_id) ||
    (deployment.context_type === 'Account' && deployment.context_id === cc.account_id)
  )
}

export const DeploymentAvailability = (props: DeploymentAvailabilityProps) => {
  const {registration, deployment, debug, refetchControls, deleteControl, editControl} = props

  const controls_with_ids = deployment.context_controls.map(cc => {
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

  const rootControl = deployment.context_controls.find(matchesDeploymentsContext(deployment))!

  const [deleteExceptionModalOpenProps, setDeleteExceptionModalOpenProps] =
    React.useState<DeleteExceptionModalOpenState>({
      open: false,
    })

  const [editControlInfo, setEditControlInfo] = React.useState<{
    control: LtiContextControl
    availableInParentContext: boolean | null
  } | null>(null)

  const [exceptionModalOpenState, setExceptionModalOpenState] =
    React.useState<ExceptionModalOpenState>({
      open: false,
    })

  const onDelete = React.useCallback(
    async (registrationId: LtiRegistrationId, controlId: LtiContextControlId) => {
      const result = await deleteControl(registrationId, controlId)

      if (isUnsuccessful(result)) {
        showFlashError(
          I18n.t(
            'There was an error deleting the exception. If the error persists, please contact support.',
          ),
        )()
      } else {
        showFlashSuccess(I18n.t('The exception was successfully deleted.'))()
        setDeleteExceptionModalOpenProps({
          open: false,
        })
        refetchControls()
      }
      return result
    },
    [deleteControl, refetchControls],
  )
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
          <Flex.Item as="div" shouldGrow shouldShrink>
            <Flex alignItems="center" as="div">
              <Flex.Item padding="0 xx-small 0 0" as="div">
                {I18n.t('Installed in %{context_name}', {
                  context_name: deployment.context_name,
                })}
              </Flex.Item>
              <Flex as="div">
                <Flex.Item>
                  <Pill color="primary">
                    {rootControl?.available ? I18n.t('Available') : I18n.t('Unavailable')}
                  </Pill>
                </Flex.Item>
              </Flex>
            </Flex>
          </Flex.Item>
          <Flex.Item as="div">
            <Flex direction="row" gap="small" justifyItems="end" as="div">
              <Flex.Item>
                <IconButton
                  id={`edit-exception-${rootControl?.id}`}
                  size="medium"
                  screenReaderLabel={I18n.t('Modify availability for %{context_name}', {
                    context_name: rootControl?.context_name,
                  })}
                  renderIcon={IconEditLine}
                  onClick={() =>
                    setEditControlInfo({control: rootControl, availableInParentContext: null})
                  }
                />
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
            </Flex>
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
        {controls_with_ids
          .filter(cc => !matchesDeploymentsContext(deployment)(cc.control))
          .map(({control}) => {
            /**
             * This is a list of all controls that are considered ancestors of the current control,
             * sorted from the root control down to the current control.
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
                <Flex direction="row" justifyItems="space-between" as="div">
                  <Flex.Item shouldGrow shouldShrink>
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
                  </Flex.Item>
                  <Flex.Item>
                    <Flex gap="small">
                      <Flex.Item>
                        <IconButton
                          id={`edit-exception-${control.id}`}
                          size="medium"
                          renderIcon={IconEditLine}
                          screenReaderLabel={I18n.t('Edit Exception for %{contextName}', {
                            contextName: control.context_name,
                          })}
                          onClick={() => {
                            setEditControlInfo({
                              control,
                              availableInParentContext: closestParent.control.available,
                            })
                          }}
                        />
                      </Flex.Item>
                      <Flex.Item>
                        <IconButton
                          id={`delete-exception-${control.id}`}
                          size="medium"
                          screenReaderLabel={I18n.t('Delete Exception for %{contextName}', {
                            contextName: control.context_name,
                          })}
                          renderIcon={IconTrashLine}
                          onClick={() => {
                            if ('course_id' in control && control.course_id) {
                              setDeleteExceptionModalOpenProps({
                                open: true,
                                availableInParentContext: closestParent?.control?.available,
                                toolName: registration.name,
                                courseControl: control,
                              })
                            } else {
                              setDeleteExceptionModalOpenProps({
                                ...props,
                                open: true,
                                availableInParentContext: closestParent?.control?.available,
                                toolName: registration.name,
                                accountControl: control,
                                childControls: deployment.context_controls.filter(
                                  c => c.path.startsWith(control.path) && c.path !== control.path,
                                ),
                              })
                            }
                          }}
                        />
                      </Flex.Item>
                    </Flex>
                  </Flex.Item>
                </Flex>
              </List.Item>
            )
          })}
      </List>
      {editControlInfo && (
        <EditExceptionModal
          {...editControlInfo}
          onClose={() => setEditControlInfo(null)}
          onSave={async (...args) => {
            const result = await editControl(...args)
            if (isSuccessful(result)) {
              refetchControls()
            }
            return result
          }}
        />
      )}
      <DeleteExceptionModal
        {...deleteExceptionModalOpenProps}
        onClose={() => setDeleteExceptionModalOpenProps({open: false})}
        onDelete={onDelete}
      />
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
