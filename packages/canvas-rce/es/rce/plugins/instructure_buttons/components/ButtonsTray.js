import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import React, { useState } from 'react';
import { CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { Flex } from '@instructure/ui-flex';
import { Tray } from '@instructure/ui-tray';
import formatMessage from "../../../../format-message.js";
import { getTrayHeight } from "../../shared/trayUtils.js";
import { CreateButtonForm } from "./CreateButtonForm/index.js";
export function ButtonsTray({
  editor,
  onUnmount,
  editing
}) {
  const _useState = useState(true),
        _useState2 = _slicedToArray(_useState, 2),
        isOpen = _useState2[0],
        setIsOpen = _useState2[1];

  const title = formatMessage('Buttons and Icons');
  return /*#__PURE__*/React.createElement(Tray, {
    "data-mce-component": true,
    label: title,
    onDismiss: () => setIsOpen(false),
    onExited: onUnmount,
    open: isOpen,
    placement: "end",
    shouldContainFocus: true,
    shouldReturnFocus: true,
    size: "regular"
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "column",
    height: getTrayHeight()
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    as: "header",
    padding: "medium"
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "row"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    shrink: true
  }, /*#__PURE__*/React.createElement(Heading, {
    as: "h2"
  }, title)), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "static",
    variant: "icon",
    onClick: () => setIsOpen(false)
  }, formatMessage('Close'))))), /*#__PURE__*/React.createElement(Flex.Item, {
    as: "slot",
    padding: "small"
  }, /*#__PURE__*/React.createElement(CreateButtonForm, {
    editor: editor,
    editing: editing,
    onClose: () => setIsOpen(false)
  }))));
}