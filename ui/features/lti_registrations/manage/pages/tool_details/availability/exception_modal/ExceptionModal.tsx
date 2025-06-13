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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconCoursesLine, IconSubaccountsLine} from '@instructure/ui-icons'
import {List} from '@instructure/ui-list'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React from 'react'
import {AccountId} from '../../../../model/AccountId'
import {LtiDeployment} from '../../../../model/LtiDeployment'
import {ContextOption} from './ContextOption'
import {ContextSearch} from './ContextSearch'
import {ContextSearchOption} from './ContextSearchOption'

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
}

type ContextControlFormState = Array<{
  context: ContextSearchOption
  available: boolean
}>

export const ExceptionModal = ({openState, onClose, accountId}: ExceptionModalProps) => {
  const close = React.useCallback(() => {
    onClose()
    setContextControlForm([])
  }, [onClose])
  const [contextControlForm, setContextControlForm] = React.useState<ContextControlFormState>([])

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
          <Heading level="h4" margin="0 0 x-small 0">
            {I18n.t('Availability and Exceptions')}
          </Heading>
          {contextControlForm.length > 0 ? (
            <List isUnstyled margin="0" itemSpacing="small">
              {contextControlForm.map((control, index) => (
                <List.Item key={index}>
                  <Flex alignItems="center">
                    <Flex.Item>
                      {control.context.type === 'course' ? (
                        <IconCoursesLine size="x-small" />
                      ) : (
                        <IconSubaccountsLine size="x-small" />
                      )}
                    </Flex.Item>
                    <Flex.Item shouldGrow>
                      <ContextOption context={control.context.context} margin="0 small" />
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
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button color="primary" type="submit">
          {I18n.t('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
