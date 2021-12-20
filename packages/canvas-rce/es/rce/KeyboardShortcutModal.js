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
import React from 'react';
import { bool, func } from 'prop-types';
import { Heading } from '@instructure/ui-heading';
import { List } from '@instructure/ui-list';
import { Text } from '@instructure/ui-text';
import { Modal } from '@instructure/ui-modal';
import { CloseButton } from '@instructure/ui-buttons';
import { View } from '@instructure/ui-view';
import formatMessage from "../format-message.js";
export default function KeyboardShortcutModal(props) {
  return /*#__PURE__*/React.createElement(Modal, {
    "data-testid": "RCE_KeyboardShortcutModal",
    "data-mce-component": true,
    label: formatMessage('Keyboard Shortcuts'),
    open: props.open,
    shouldCloseOnDocumentClick: true,
    shouldReturnFocus: true,
    size: "auto",
    onClose: props.onClose,
    onExited: props.onExited,
    onDismiss: props.onDismiss
  }, /*#__PURE__*/React.createElement(Modal.Header, null, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "end",
    offset: "medium",
    variant: "icon",
    onClick: props.onDismiss
  }, formatMessage('Close')), /*#__PURE__*/React.createElement(Heading, null, formatMessage('Keyboard Shortcuts'))), /*#__PURE__*/React.createElement(Modal.Body, null, /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "small"
  }, /*#__PURE__*/React.createElement(List, {
    variant: "unstyled"
  }, /*#__PURE__*/React.createElement(List.Item, null, /*#__PURE__*/React.createElement(Text, {
    weight: "bold"
  }, "ALT+F8/ALT+0"), ' ', formatMessage('Open this keyboard shortcuts dialog')), /*#__PURE__*/React.createElement(List.Item, null, /*#__PURE__*/React.createElement(Text, {
    weight: "bold"
  }, "CTRL+F9"), " ", formatMessage('Focus element options toolbar')), /*#__PURE__*/React.createElement(List.Item, null, /*#__PURE__*/React.createElement(Text, {
    weight: "bold"
  }, "ALT+F9"), " ", formatMessage("Go to the editor's menubar")), /*#__PURE__*/React.createElement(List.Item, null, /*#__PURE__*/React.createElement(Text, {
    weight: "bold"
  }, "ALT+F10"), " ", formatMessage("Go to the editor's toolbar")), /*#__PURE__*/React.createElement(List.Item, null, /*#__PURE__*/React.createElement(Text, {
    weight: "bold"
  }, "ESC"), ' ', formatMessage('Close a menu or dialog. Also returns you to the editor area')), /*#__PURE__*/React.createElement(List.Item, null, /*#__PURE__*/React.createElement(Text, {
    weight: "bold"
  }, formatMessage('TAB/Arrows')), ' ', formatMessage('Navigate through the menu or toolbar'))), /*#__PURE__*/React.createElement(View, {
    as: "p"
  }, formatMessage('Other editor shortcuts may be found at'), ' ', /*#__PURE__*/React.createElement("a", {
    href: "https://www.tiny.cloud/docs/advanced/keyboard-shortcuts/",
    target: "rcekbshortcut"
  }, "https://www.tiny.cloud/docs/advanced/keyboard-shortcuts/")))));
}
KeyboardShortcutModal.propTypes = {
  open: bool.isRequired,
  onClose: func,
  onDismiss: func.isRequired,
  onExited: func
};