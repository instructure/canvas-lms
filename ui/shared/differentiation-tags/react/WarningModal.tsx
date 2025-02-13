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

import React from 'react'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('differentiation_tags')

type BaseModalProps = {
  open: boolean
  title: string
  onClose: () => void
  onContinue: () => void
  children: React.ReactNode
  cancelText?: string
  continueText?: string
}

const BaseWarningModal: React.FC<BaseModalProps> = ({
  open,
  title,
  onClose,
  onContinue,
  children,
  cancelText = 'Cancel',
  continueText = 'Confirm',
}) => {
  return (
    <Modal
      as="form"
      open={open}
      onDismiss={onClose}
      label={title}
      shouldCloseOnDocumentClick
      size="small"
    >
      <Modal.Header>
        <Flex>
          <Flex.Item shouldGrow>
            <Heading>{title}</Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton onClick={onClose} screenReaderLabel="Close" />
          </Flex.Item>
        </Flex>
      </Modal.Header>
      <Modal.Body padding="none medium">{children}</Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} margin="0 x-small 0 0">
          {cancelText}
        </Button>
        <Button onClick={onContinue} color="primary" type="submit">
          {continueText}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export const DeleteTagWarningModal: React.FC<{
  open: boolean
  onClose: () => void
  onContinue: () => void
}> = ({open, onClose, onContinue}) => {
  return (
    <BaseWarningModal open={open} title="Delete Tag" onClose={onClose} onContinue={onContinue}>
      <View>
        <Text>
          <p>
            {I18n.t(
              'Deleting this tag preserves past assignments in the gradebook and removes students from upcoming assignments where they have been assigned via this tag.',
            )}
          </p>
        </Text>
        <Text>
          <p>
            {I18n.t(
              'For assignments that are currently available and have a deadline that has not yet passed, indicate below which should continue to be assigned to tagged students. Unchecked assignments will no longer be assigned to students with the deleted tag and their submissions will be deleted.',
            )}
          </p>
        </Text>
      </View>
    </BaseWarningModal>
  )
}

export const RemoveTagWarningModal: React.FC<{
  open: boolean
  onClose: () => void
  onContinue: () => void
}> = ({open, onClose, onContinue}) => {
  return (
    <BaseWarningModal open={open} title="Remove Tag" onClose={onClose} onContinue={onContinue}>
      <View>
        <Text>
          <p>
            {I18n.t(
              'Removing the tag from a student preserves past assignments in the gradebook and removes the student from any upcoming assignments where they have been assigned via tag.',
            )}
          </p>
        </Text>
        <Text>
          <p>
            {I18n.t(
              'For assignments that are currently available and have a deadline that has not yet passed, indicate below which should continue to be assigned to the student, unchecked assignments will no longer be assigned to that student.',
            )}
          </p>
        </Text>
      </View>
    </BaseWarningModal>
  )
}
