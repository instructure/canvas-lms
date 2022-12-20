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
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {Text} from '@instructure/ui-text'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import formatMessage from '../format-message'
import {determineOSDependentKey} from './userOS'
import {instuiPopupMountNode} from '../util/fullscreenHelpers'

export default function KeyboardShortcutModal(props) {
  const OSKey = determineOSDependentKey()

  return (
    <Modal
      data-testid="RCE_KeyboardShortcutModal"
      data-mce-component={true}
      label={formatMessage('Keyboard Shortcuts')}
      mountNode={instuiPopupMountNode}
      open={props.open}
      shouldCloseOnDocumentClick={true}
      shouldReturnFocus={true}
      size="auto"
      onClose={props.onClose}
      onExited={props.onExited}
      onDismiss={props.onDismiss}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          color="primary"
          onClick={props.onDismiss}
          screenReaderLabel={formatMessage('Close')}
        />
        <Heading>{formatMessage('Keyboard Shortcuts')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div" margin="small">
          <List isUnstyled={true}>
            <List.Item>
              <Text weight="bold">
                {OSKey}+F8/{OSKey}+0
              </Text>{' '}
              {formatMessage('Open this keyboard shortcuts dialog')}
            </List.Item>
            <List.Item>
              <Text weight="bold">CTRL+F9</Text> {formatMessage('Focus element options toolbar')}
            </List.Item>
            <List.Item>
              <Text weight="bold">{OSKey}+F9</Text> {formatMessage("Go to the editor's menubar")}
            </List.Item>
            <List.Item>
              <Text weight="bold">{OSKey}+F10</Text> {formatMessage("Go to the editor's toolbar")}
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
  onClose: func,
  onDismiss: func.isRequired,
  onExited: func,
}
