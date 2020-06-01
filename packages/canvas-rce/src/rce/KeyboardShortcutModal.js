/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {bool, func} from 'prop-types'
import {Heading, List, Text} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-layout'
import formatMessage from '../format-message'

export default function KeyboardShortcutModal(props) {
  return (
    <Modal
      data-testid="RCE_KeyboardShortcutModal"
      data-mce-component
      label={formatMessage('Keyboard Shortcuts')}
      open={props.open}
      shouldCloseOnDocumentClick
      shouldReturnFocus
      size="auto"
      onClose={props.onClose}
      onDismiss={props.onDismiss}
    >
      <Modal.Header>
        <CloseButton placement="end" offset="medium" variant="icon" onClick={props.onDismiss}>
          {formatMessage('Close')}
        </CloseButton>
        <Heading>{formatMessage('Keyboard Shortcuts')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="small">
          <List variant="unstyled">
            <List.Item>
              <Text weight="bold">ALT+F8/ALT+0</Text>{' '}
              {formatMessage('Open this keyboard shortcuts dialog')}
            </List.Item>
            <List.Item>
              <Text weight="bold">CTRL+F9</Text> {formatMessage('Focus element options toolbar')}
            </List.Item>
            <List.Item>
              <Text weight="bold">ALT+F9</Text> {formatMessage("Go to the editor's menubar")}
            </List.Item>
            <List.Item>
              <Text weight="bold">ALT+F10</Text> {formatMessage("Go to the editor's toolbar")}
            </List.Item>
            <List.Item>
              <Text weight="bold">ESC</Text>{' '}
              {formatMessage('Close a menu or dialog. Also returns you to the editor area')}
            </List.Item>
            <List.Item>
              <Text weight="bold">{formatMessage('TAB/Arrows')}</Text>{' '}
              {formatMessage('Navigate through the menu or toolbar')}
            </List.Item>
          </List>
          <View as="p">
            {formatMessage('Other editor shortcuts may be found at')}{' '}
            <a
              href="https://www.tiny.cloud/docs/advanced/keyboard-shortcuts/"
              target="rcekbshortcut"
            >
              https://www.tiny.cloud/docs/advanced/keyboard-shortcuts/
            </a>
          </View>
        </View>
      </Modal.Body>
    </Modal>
  )
}

KeyboardShortcutModal.propTypes = {
  open: bool.isRequired,
  onClose: func.isRequired,
  onDismiss: func.isRequired
}
