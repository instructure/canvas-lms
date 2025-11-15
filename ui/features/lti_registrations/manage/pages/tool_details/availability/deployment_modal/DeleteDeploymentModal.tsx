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

import {useRef} from 'react'
import type {DeleteDeployment} from '../../../../api/deployments'
import type {LtiDeployment} from '../../../../model/LtiDeployment'
import listFormatterPolyfill from '@canvas/util/listFormatter'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useMutation} from '@tanstack/react-query'
import {isUnsuccessful} from '../../../../../common/lib/apiResult/ApiResult'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {List} from '@instructure/ui-list'
import {Alert} from '@instructure/ui-alerts'
import {ContextCard} from '../ContextCard'
import {toUndefined} from '../../../../../common/lib/toUndefined'
import {nearestParentControl} from '../nearestParentControl'
import {findRootContextControl} from '../findRootContextControl'
import type {LtiContextControl} from '../../../../model/LtiContextControl'
import type {LtiRegistration} from '../../../../model/LtiRegistration'
import {Text} from '@instructure/ui-text'

const listFormatter = Intl.ListFormat
  ? new Intl.ListFormat(ENV.LOCALE || navigator.language)
  : listFormatterPolyfill

const I18n = createI18nScope('lti_registrations')

export type DeleteDeploymentModalProps = {
  deployment: LtiDeployment
  registration: LtiRegistration
  controlsByPath: Map<string, LtiContextControl>
  onClose: () => void
  onDelete: DeleteDeployment
}

export const DeleteDeploymentModal = ({
  onClose,
  onDelete,
  deployment,
  registration,
  controlsByPath,
}: DeleteDeploymentModalProps) => {
  const cancelRef = useRef<Element | null>(null)

  const deleteDeployment = useMutation({
    mutationKey: ['lti_registrations', 'delete_deployment'],
    mutationFn: async (deployment: LtiDeployment) =>
      onDelete({
        registrationId: registration.id,
        accountId: registration.account_id,
        deploymentId: deployment.id,
      }),
    // We don't need an onError handler here because ApiResult is meant to be a discriminated union
    // that indicates success or failure within the result object itself.
    onSuccess: result => {
      if (isUnsuccessful(result)) {
        console.error('Error deleting deployment', result)
        showFlashError(
          I18n.t(
            'Unable to delete deployment. Please try again. If the error persists, please contact support.',
          ),
        )()
      } else {
        onClose()
        showFlashSuccess(I18n.t('Deployment deleted successfully.'))()
      }
    },
    scope: {
      id: `delete-deployment-${deployment.id}`,
    },
  })

  const rootContextControl = findRootContextControl(deployment)
  const contextControls = deployment.context_controls || []

  return (
    <Modal
      open={true}
      label={I18n.t('Delete Deployment')}
      size="medium"
      defaultFocusElement={() => cancelRef.current}
      shouldCloseOnDocumentClick={true}
      onDismiss={onClose}
    >
      <Modal.Header>
        <Heading>{I18n.t('Delete Deployment')}</Heading>
        <CloseButton placement="end" offset="small" onClick={onClose} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body padding="medium medium">
        {deleteDeployment.isPending ? (
          <Flex justifyItems="center" alignItems="center" margin="small">
            <Flex.Item>
              <Spinner size="large" margin="0 small" renderTitle={I18n.t('Deleting exceptions')} />
            </Flex.Item>
          </Flex>
        ) : (
          <Flex direction="column" gap="medium" margin="0">
            <Alert margin="0" variant="warning">
              {createWarningMessage(deployment, registration.name)}
            </Alert>
            <Heading level="h3" margin="0 0 0 0">
              {I18n.t(
                {
                  one: 'Exception to be deleted:',
                  other: 'Exceptions to be deleted:',
                },
                {
                  count: contextControls.length,
                },
              )}
            </Heading>
            <List isUnstyled itemSpacing="small" margin="0">
              {contextControls.map(control => (
                <List.Item key={control.id}>
                  <ContextCard
                    context_name={control.context_name}
                    inherit_note={
                      control.available === nearestParentControl(control, controlsByPath)?.available
                    }
                    course_id={toUndefined(control.course_id)}
                    account_id={toUndefined(control.account_id)}
                    exception_counts={{
                      child_control_count: control.child_control_count,
                      course_count: control.course_count,
                      subaccount_count: control.subaccount_count,
                    }}
                    path_segments={control.display_path}
                    depth={control.depth}
                    available={control.available}
                    path={control.path}
                  />
                </List.Item>
              ))}
              {rootContextControl.child_control_count > contextControls.length && (
                <List.Item>
                  <Text>
                    {I18n.t(
                      {
                        one: '1 additional exception not shown.',
                        other: '%{count} additional exceptions not shown.',
                      },
                      {
                        count: rootContextControl.child_control_count - contextControls.length,
                      },
                    )}
                  </Text>
                </List.Item>
              )}
            </List>
          </Flex>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button
          margin="0 small 0 0"
          onClick={onClose}
          elementRef={button => (cancelRef.current = button)}
        >
          {I18n.t('Cancel')}
        </Button>
        <Button
          id="delete-deployment-modal-button"
          color="danger"
          interaction={deleteDeployment.isPending ? 'disabled' : 'enabled'}
          onClick={() => deleteDeployment.mutate(deployment)}
        >
          {I18n.t('Delete')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

const createWarningMessage = (deployment: LtiDeployment, toolName: string) => {
  // All deployments must have a root context control in the same context as themselves, so this
  // should never be undefined.
  const rootContextControl = findRootContextControl(deployment)

  if (rootContextControl.course_id) {
    return I18n.t(
      'After this change, the %{toolName} tool (Deployment ID: %{deploymentId}) will be deleted from course %{courseName}.',
      {
        toolName,
        deploymentId: deployment.deployment_id,
        courseName: rootContextControl.context_name,
      },
    )
  }

  const subAccountMessage = I18n.t(
    {
      one: '1 child sub-account',
      other: '%{count} child sub-accounts',
    },
    {count: rootContextControl.subaccount_count},
  )

  const courseMessage = I18n.t(
    {
      one: '1 child course',
      other: '%{count} child courses',
    },
    {count: rootContextControl.course_count},
  )

  return I18n.t(
    'After this change, the %{toolName} tool (Deployment ID: %{deploymentId}) will be deleted from %{accountName}, including %{results}.',
    {
      toolName,
      deploymentId: deployment.deployment_id,
      accountName: deployment.context_name,
      results: listFormatter.format([subAccountMessage, courseMessage]),
    },
  )
}
