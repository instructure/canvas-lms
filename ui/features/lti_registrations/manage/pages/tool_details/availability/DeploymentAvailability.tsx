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
  type DeleteContextControl,
  type UpdateContextControl,
} from '../../../api/contextControls'
import {type AccountId, ZAccountId} from '../../../model/AccountId'
import {ZCourseId} from '../../../model/CourseId'
import type {LtiContextControl, LtiContextControlId} from '../../../model/LtiContextControl'
import type {LtiDeployment} from '../../../model/LtiDeployment'
import type {LtiRegistrationWithAllInformation} from '../../../model/LtiRegistration'
import type {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {ContextCard} from './ContextCard'
import {
  DeleteExceptionModal,
  type DeleteExceptionModalOpenState,
} from './exception_modal/DeleteExceptionModal'
import {findRootContextControl} from './findRootContextControl'
import {EditExceptionModal} from './exception_modal/EditExceptionModal'
import {ExceptionModal, type ExceptionModalOpenState} from './exception_modal/ExceptionModal'
import {renderExceptionCounts} from './renderExceptionCounts'
import {buildControlsByPath, nearestParentControl} from './nearestParentControl'
import {DeleteDeploymentModal} from './deployment_modal/DeleteDeploymentModal'
import type {DeleteDeployment} from '../../../api/deployments'

import {Tag} from '@instructure/ui-tag'
import {Grid} from '@instructure/ui-grid'
const I18n = createI18nScope('lti_registrations')

export type DeploymentAvailabilityProps = {
  accountId: AccountId
  deployment: LtiDeployment
  registration: LtiRegistrationWithAllInformation
  deleteControl: DeleteContextControl
  deleteDeployment: DeleteDeployment
  editControl: UpdateContextControl
  refetchControls: () => void
}

export const DeploymentAvailability = (props: DeploymentAvailabilityProps) => {
  const {registration, deleteDeployment, deployment, refetchControls, deleteControl, editControl} =
    props

  const controls_with_ids = React.useMemo(
    () => buildControlsByPath(deployment.context_controls || []),
    [deployment.context_controls || []],
  )

  // Every deployment must have a root control.
  const rootControl = React.useMemo(() => findRootContextControl(deployment)!, [deployment])

  const [openDeleteDeploymentModal, setOpenDeleteDeploymentModal] = React.useState(false)

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
      <Grid
        startAt="large"
        // visualDebug
        vAlign="middle"
        hAlign="start"
        colSpacing="small"
        rowSpacing="small"
      >
        <Grid.Row>
          <Grid.Col>
            <Flex direction="row" gap="small" alignItems="center">
              <Heading level="h3">
                {I18n.t('Installed in %{context_name}', {
                  context_name: deployment.context_name,
                })}
              </Heading>
              <Tag text={rootControl?.available ? I18n.t('Available') : I18n.t('Not Available')} />
            </Flex>
          </Grid.Col>

          <Grid.Col width="auto">
            <Flex direction="row" gap="small">
              <IconButton
                id={`edit-exception-${rootControl.id}`}
                data-pendo="lti-registrations-edit-root-control-availability"
                size="medium"
                screenReaderLabel={I18n.t('Modify availability for %{context_name}', {
                  context_name: rootControl.context_name,
                })}
                renderIcon={IconEditLine}
                onClick={() =>
                  setEditControlInfo({control: rootControl, availableInParentContext: null})
                }
              />
              {!deployment.root_account_deployment && (
                <IconButton
                  id={`delete-deployment-${deployment.id}`}
                  data-pendo="lti-registrations-delete-deployment"
                  size="medium"
                  screenReaderLabel={I18n.t('Delete Deployment for %{context_name}', {
                    context_name: rootControl.context_name,
                  })}
                  renderIcon={IconTrashLine}
                  onClick={() => setOpenDeleteDeploymentModal(true)}
                />
              )}
              {deployment.context_type !== 'Course' ? (
                <Button
                  data-pendo="lti-registrations-open-add-exception-modal"
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
              ) : undefined}
            </Flex>
          </Grid.Col>
        </Grid.Row>
      </Grid>
      <ExceptionModal
        accountId={props.accountId}
        registrationId={registration.id}
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
          <Link
            to={`/manage/${registration.id}/configuration#placements`}
            as={RouterLink}
            data-pendo="lti-registrations-placements-link"
          >
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
        {(deployment.context_controls || [])
          .filter(cc => cc.id !== rootControl.id)
          .map(control => {
            // We know that we'll always find a parent control, because the root control is always present.
            const closestParent = nearestParentControl(control, controls_with_ids)!
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
                      inherit_note={closestParent.available === control.available}
                    />
                  </Flex.Item>
                  <Flex.Item>
                    <Flex gap="small">
                      <Flex.Item>
                        <IconButton
                          id={`edit-exception-${control.id}`}
                          data-pendo="lti-registrations-edit-exception"
                          size="medium"
                          renderIcon={IconEditLine}
                          screenReaderLabel={I18n.t('Edit Exception for %{contextName}', {
                            contextName: control.context_name,
                          })}
                          onClick={() => {
                            setEditControlInfo({
                              control,
                              availableInParentContext: closestParent?.available ?? false,
                            })
                          }}
                        />
                      </Flex.Item>
                      <Flex.Item>
                        <IconButton
                          id={`delete-exception-${control.id}`}
                          data-pendo="lti-registrations-delete-exception"
                          size="medium"
                          screenReaderLabel={I18n.t('Delete Exception for %{contextName}', {
                            contextName: control.context_name,
                          })}
                          renderIcon={IconTrashLine}
                          onClick={() => {
                            if ('course_id' in control && control.course_id) {
                              setDeleteExceptionModalOpenProps({
                                open: true,
                                availableInParentContext: closestParent.available,
                                toolName: registration.name,
                                courseControl: control,
                              })
                            } else {
                              setDeleteExceptionModalOpenProps({
                                ...props,
                                open: true,
                                availableInParentContext: closestParent.available,
                                toolName: registration.name,
                                accountControl: control,
                                childControls: (deployment.context_controls || []).filter(
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
      {openDeleteDeploymentModal && (
        <DeleteDeploymentModal
          deployment={deployment}
          registration={registration}
          controlsByPath={controls_with_ids}
          onClose={() => setOpenDeleteDeploymentModal(false)}
          onDelete={async (...args) => {
            const result = await deleteDeployment(...args)
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
    </View>
  )
}
