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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconCoursesLine, IconSubaccountsLine, IconTrashLine} from '@instructure/ui-icons'
import {List} from '@instructure/ui-list'
import {Modal} from '@instructure/ui-modal'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useMutation} from '@tanstack/react-query'
import React from 'react'
import {ContextControlParameter} from '../../../../api/contextControls'
import {AccountId} from '../../../../model/AccountId'
import {LtiDeployment} from '../../../../model/LtiDeployment'
import {LtiDeploymentId} from '../../../../model/LtiDeploymentId'
import {ContextOption} from './ContextOption'
import {ContextSearch} from './ContextSearch'
import {ContextSearchOption} from './ContextSearchOption'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('lti_registrations')

export type ExceptionModalOpenState =
  | {
      open: false
    }
  | {
      open: true
      deployment: LtiDeployment
    }

export type ExceptionModalProps = {
  accountId: AccountId
  openState: ExceptionModalOpenState
  onClose: () => void
  onConfirm: (controls: ContextControlParameter[]) => Promise<void>
}

type ContextControlFormState = Array<{
  context: ContextSearchOption
  available: boolean
}>

export const ExceptionModal = ({openState, onClose, accountId, onConfirm}: ExceptionModalProps) => {
  const [contextControlForm, setContextControlForm] = React.useState<ContextControlFormState>([])

  const confirmHandler = useMutation({
    mutationFn: onConfirm,
  })

  const close = () => {
    onClose()
    setTimeout(() => {
      setContextControlForm([])
      confirmHandler.reset()
    }, 500) // Delay to allow modal to close before resetting state
  }

  /**
   * Not using `confirmHandler.isLoading` directly
   * because we don't want a flash in them modal
   * after the mutation finishes but before the modal closes.
   */
  const disableView = !confirmHandler.isIdle

  return (
    <Modal open={openState.open} label={I18n.t('Add Availability and Exceptions')} size="medium">
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={close} screenReaderLabel="Close" />
        <Heading>{I18n.t('Add Availability and Exceptions')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View minHeight="20em" as="div">
          <View margin="0 0 medium 0" as="div">
            <ContextSearch
              disabled={disableView}
              accountId={accountId}
              onSelectContext={context => {
                // Handle context selection here
                // Check if the context is already in the form
                const existingControl = contextControlForm.find(
                  control => control.context.context.id === context.context.id,
                )
                if (!existingControl) {
                  setContextControlForm(prev => [...prev, {context, available: false}])
                }
              }}
            />
          </View>

          {disableView ? (
            <Flex alignItems="center" justifyItems="center">
              <Flex.Item margin="medium 0 0 0">
                <Spinner renderTitle={I18n.t('Saving Exceptions')} />
              </Flex.Item>
            </Flex>
          ) : (
            <>
              <Heading level="h4" margin="0 0 x-small 0">
                {I18n.t('Availability and Exceptions')}
              </Heading>
              {contextControlForm.length > 0 ? (
                <List isUnstyled margin="0" itemSpacing="small">
                  {contextControlForm.map((control, index) => (
                    <List.Item key={index}>
                      <Flex alignItems="center" gap="x-small">
                        <Flex.Item>
                          {control.context.type === 'course' ? (
                            <IconCoursesLine size="x-small" />
                          ) : (
                            <IconSubaccountsLine size="x-small" />
                          )}
                        </Flex.Item>
                        <Flex.Item shouldGrow shouldShrink>
                          <ContextOption context={control.context.context} />
                        </Flex.Item>
                        <Flex.Item>
                          <SimpleSelect
                            renderLabel=""
                            value={control.available ? 'available' : 'unavailable'}
                            onChange={(e, {value}) => {
                              // Update the availability status of the context
                              setContextControlForm(prev =>
                                prev.map((c, i) =>
                                  i === index ? {...c, available: value === 'available'} : c,
                                ),
                              )
                            }}
                          >
                            <SimpleSelect.Option id={`available`} value={'available'}>
                              {I18n.t('Available')}
                            </SimpleSelect.Option>
                            <SimpleSelect.Option id={`unavailable`} value={'unavailable'}>
                              {I18n.t('Not Available')}
                            </SimpleSelect.Option>
                          </SimpleSelect>
                        </Flex.Item>
                        <Flex.Item>
                          <IconButton
                            screenReaderLabel={I18n.t('Delete exception for %{context_name}', {
                              context_name: control.context.context.name,
                            })}
                            onClick={() => {
                              // Remove the context from the context control form
                              setContextControlForm(prev => prev.filter((_c, i) => i !== index))
                            }}
                          >
                            <IconTrashLine />
                          </IconButton>
                        </Flex.Item>
                      </Flex>
                    </List.Item>
                  ))}
                </List>
              ) : (
                <Text>
                  {I18n.t(
                    'You have not added any availability or exceptions. Search or browse to add one.',
                  )}
                </Text>
              )}
            </>
          )}
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button
          color="primary"
          type="submit"
          disabled={disableView}
          onClick={() => {
            if (openState.open === true) {
              confirmHandler
                .mutateAsync(
                  contextControlForm.map(convertToContextControl(openState.deployment.id)),
                )
                .finally(close)
            }
          }}
        >
          {I18n.t('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

const convertToContextControl =
  (deploymentId: LtiDeploymentId) =>
  (controlState: ContextControlFormState[number]): ContextControlParameter => {
    if (controlState.context.type === 'account') {
      return {
        available: controlState.available,
        account_id: controlState.context.context.id,
        deployment_id: deploymentId,
      }
    } else {
      return {
        available: controlState.available,
        course_id: controlState.context.context.id,
        deployment_id: deploymentId,
      }
    }
  }
