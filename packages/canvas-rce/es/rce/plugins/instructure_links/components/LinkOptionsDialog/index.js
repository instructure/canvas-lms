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
import React, { useEffect, useState } from 'react';
import { bool, func, oneOf, string } from 'prop-types';
import { Alert } from '@instructure/ui-alerts';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { TextInput } from '@instructure/ui-text-input';
import { Modal } from '@instructure/ui-modal';
import { View } from '@instructure/ui-view';
import formatMessage from "../../../../../format-message.js";
import validateURL from "../../validateURL.js";
const CREATE_LINK = 'create';
const EDIT_LINK = 'edit';
export default function LinkOptionsDialog(props) {
  const _useState = useState(props.text || ''),
        _useState2 = _slicedToArray(_useState, 2),
        text = _useState2[0],
        setText = _useState2[1];

  const _useState3 = useState(props.url || ''),
        _useState4 = _slicedToArray(_useState3, 2),
        url = _useState4[0],
        setUrl = _useState4[1];

  const _useState5 = useState(null),
        _useState6 = _slicedToArray(_useState5, 2),
        err = _useState6[0],
        setErr = _useState6[1];

  const _useState7 = useState(false),
        _useState8 = _slicedToArray(_useState7, 2),
        isValidURL = _useState8[0],
        setIsValidURL = _useState8[1];

  useEffect(() => {
    try {
      const v = validateURL(url);
      setIsValidURL(v);
      setErr(null);
    } catch (ex) {
      setIsValidURL(false);
      setErr(ex.message);
    }
  }, [url]);

  function handleSave(event) {
    event.preventDefault();
    if (!url) return;
    const linkText = text.trim() || url;
    props.onSave({
      text: linkText,
      target: '_blank',
      href: url,
      userText: props.showText,
      class: 'inline_disabled',
      forceRename: true
    });
  }

  const label = props.operation === CREATE_LINK ? formatMessage('Insert Link') : formatMessage('Edit Link');
  return /*#__PURE__*/React.createElement(Modal, {
    "data-testid": "RCELinkOptionsDialog",
    "data-mce-component": true,
    as: "form",
    label: label,
    onDismiss: props.onRequestClose,
    onEntered: props.onEntered,
    onExited: props.onExited,
    onSubmit: handleSave,
    open: props.open,
    shouldCloseOnDocumentClick: true,
    shouldReturnFocus: false,
    size: "medium"
  }, /*#__PURE__*/React.createElement(Modal.Header, null, /*#__PURE__*/React.createElement(CloseButton, {
    offset: "medium",
    placement: "end",
    screenReaderLabel: formatMessage('Close'),
    onClick: props.onRequestClose
  }), /*#__PURE__*/React.createElement(Heading, null, label)), /*#__PURE__*/React.createElement(Modal.Body, null, props.showText && /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "small"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: formatMessage('Text'),
    name: "linktext",
    onChange: function (event) {
      setText(event.target.value);
    },
    value: text
  })), /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "small"
  }, /*#__PURE__*/React.createElement(TextInput, {
    renderLabel: formatMessage('Link'),
    name: "linklink",
    onChange: function (event) {
      setUrl(event.target.value);
    },
    value: url
  })), err && /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "small",
    "data-testid": "url-error"
  }, /*#__PURE__*/React.createElement(Alert, {
    variant: "error"
  }, err))), /*#__PURE__*/React.createElement(Modal.Footer, null, /*#__PURE__*/React.createElement("input", {
    type: "submit",
    style: {
      display: 'none'
    }
  }), /*#__PURE__*/React.createElement(Button, {
    onClick: props.onRequestClose,
    margin: "0 small",
    color: "secondary"
  }, formatMessage('Close')), /*#__PURE__*/React.createElement(Button, {
    disabled: !(url && isValidURL),
    onClick: handleSave,
    color: "primary"
  }, formatMessage('Done'))));
}
LinkOptionsDialog.propTypes = {
  text: string,
  url: string,
  operation: oneOf(["create", "edit"]),
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired,
  showText: bool
};
LinkOptionsDialog.defaultProps = {
  onEntered: null,
  onExited: null,
  showText: true
};