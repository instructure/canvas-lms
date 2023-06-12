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
import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import formatMessage from '../format-message'
import {determineOSDependentKey} from './userOS'
import {instuiPopupMountNode} from '../util/fullscreenHelpers'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

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
        <View as="div" padding="x-small xx-large large x-large">
          <Table margin="small" caption={formatMessage('Keyboard Shortcuts')}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="shortcut_header">
                  <ScreenReaderContent>{formatMessage('Shortcut')}</ScreenReaderContent>
                </Table.ColHeader>
                <Table.ColHeader id="description_header">
                  <ScreenReaderContent>{formatMessage('Description')}</ScreenReaderContent>
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              <Table.Row>
                <Table.Cell>
                  <Text weight="bold">{OSKey}+F8</Text>
                </Table.Cell>
                <Table.Cell>{formatMessage('Open this keyboard shortcuts dialog')}</Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Text weight="bold">{formatMessage('SHIFT+Arrows')}</Text>
                </Table.Cell>
                <Table.Cell>
                  {formatMessage('Highlight an element to activate the element options toolbar')}
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Text weight="bold">CTRL+F9</Text>
                </Table.Cell>
                <Table.Cell>{formatMessage('Focus element options toolbar')}</Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Text weight="bold">{OSKey}+F9</Text>
                </Table.Cell>
                <Table.Cell>{formatMessage("Go to the editor's menubar")}</Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Text weight="bold">{OSKey}+F10</Text>
                </Table.Cell>
                <Table.Cell>{formatMessage("Go to the editor's toolbar")}</Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Text weight="bold">ESC</Text>
                </Table.Cell>
                <Table.Cell>
                  {formatMessage('Close a menu or dialog. Also returns you to the editor area')}
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Text weight="bold">{formatMessage('TAB/Arrows')}</Text>
                </Table.Cell>
                <Table.Cell>{formatMessage('Navigate through the menu or toolbar')}</Table.Cell>
              </Table.Row>
            </Table.Body>
          </Table>
          <View as="p" padding="large 0 0 0" margin="0 0 0 small">
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
