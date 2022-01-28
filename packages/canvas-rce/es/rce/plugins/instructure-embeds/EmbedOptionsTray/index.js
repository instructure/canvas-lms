import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

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
import React, { useState } from 'react';
import { bool, func, shape, string } from 'prop-types';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { RadioInput, RadioInputGroup } from '@instructure/ui-radio-input';
import { TextInput } from '@instructure/ui-text-input';
import { Flex } from '@instructure/ui-flex';
import { Tray } from '@instructure/ui-tray';
import formatMessage from "../../../../format-message.js";
import { getTrayHeight } from "../../shared/trayUtils.js";
export default function EmbedOptionsTray(props) {
  const content = props.content;

  const _useState = useState(content.text),
        _useState2 = _slicedToArray(_useState, 2),
        text = _useState2[0],
        setText = _useState2[1];

  const _useState3 = useState(content.url),
        _useState4 = _slicedToArray(_useState3, 2),
        link = _useState4[0],
        setLink = _useState4[1];

  const _useState5 = useState(content.displayAs),
        _useState6 = _slicedToArray(_useState5, 2),
        displayAs = _useState6[0],
        setDisplayAs = _useState6[1];

  return /*#__PURE__*/React.createElement(Tray, {
    label: formatMessage('Embed Options Tray'),
    onDismiss: props.onRequestClose,
    onEntered: props.onEntered,
    onExited: props.onExited,
    open: props.open,
    placement: "end",
    shouldCloseOnDocumentClick: true,
    shouldContainFocus: true,
    shouldReturnFocus: true
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
  }, formatMessage('Options'))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(CloseButton, {
    onClick: props.onRequestClose
  }, formatMessage('Close'))))), /*#__PURE__*/React.createElement(Flex.Item, {
    as: "form",
    grow: true,
    margin: "none",
    shrink: true
  }, /*#__PURE__*/React.createElement(Flex, {
    justifyItems: "space-between",
    direction: "column",
    height: "100%"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    grow: true,
    padding: "small",
    shrink: true
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "column"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: formatMessage('Text'),
    onChange: function (event) {
      setText(event.target.value);
    },
    value: text
  })), /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: formatMessage('Link'),
    onChange: function (event) {
      setLink(event.target.value);
    },
    value: link
  })), /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "small none none none",
    padding: "small"
  }, /*#__PURE__*/React.createElement(RadioInputGroup, {
    description: formatMessage('Display Options'),
    name: "display-content-as",
    onChange: function (event) {
      setDisplayAs(event.target.value);
    },
    value: displayAs
  }, /*#__PURE__*/React.createElement(RadioInput, {
    label: formatMessage('Embed Preview'),
    value: "embed"
  }), /*#__PURE__*/React.createElement(RadioInput, {
    label: formatMessage('Display Text Link (Opens in a new tab)'),
    value: "link"
  }))))), /*#__PURE__*/React.createElement(Flex.Item, {
    background: "secondary",
    borderWidth: "small none none none",
    padding: "small medium",
    textAlign: "end"
  }, /*#__PURE__*/React.createElement(Button, {
    disabled: text === '' || link === '',
    onClick: function (event) {
      event.preventDefault();
      props.onSave({
        displayAs,
        text,
        url: link
      });
    },
    variant: "primary"
  }, formatMessage('Done')))))));
}
EmbedOptionsTray.propTypes = {
  content: shape({
    text: string.isRequired,
    url: string.isRequired
  }).isRequired,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
};
EmbedOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
};