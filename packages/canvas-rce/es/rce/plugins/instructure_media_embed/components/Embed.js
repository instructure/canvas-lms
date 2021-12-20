import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import { Modal } from '@instructure/ui-modal';
import formatMessage from "../../../../format-message.js";
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { func } from 'prop-types';
import { TextArea } from '@instructure/ui-text-area';
export function Embed({
  onSubmit,
  onDismiss
}) {
  const _useState = useState(''),
        _useState2 = _slicedToArray(_useState, 2),
        embedCode = _useState2[0],
        setEmbedCode = _useState2[1];

  return /*#__PURE__*/React.createElement(Modal, {
    "data-mce-component": true,
    label: formatMessage('Embed'),
    size: "medium",
    onDismiss: onDismiss,
    open: true,
    shouldCloseOnDocumentClick: false
  }, /*#__PURE__*/React.createElement(Modal.Header, null, /*#__PURE__*/React.createElement(CloseButton, {
    onClick: onDismiss,
    offset: "medium",
    placement: "end"
  }, formatMessage('Close')), /*#__PURE__*/React.createElement(Heading, null, formatMessage('Embed'))), /*#__PURE__*/React.createElement(Modal.Body, null, /*#__PURE__*/React.createElement(TextArea, {
    maxHeight: "10rem",
    label: formatMessage('Embed Code'),
    value: embedCode,
    onChange: e => {
      setEmbedCode(e.target.value);
    }
  })), /*#__PURE__*/React.createElement(Modal.Footer, null, /*#__PURE__*/React.createElement(Button, {
    onClick: onDismiss
  }, formatMessage('Close')), "\xA0", /*#__PURE__*/React.createElement(Button, {
    onClick: e => {
      e.preventDefault();
      onSubmit(embedCode);
      onDismiss();
    },
    variant: "primary",
    type: "submit",
    disabled: !embedCode
  }, formatMessage('Submit'))));
}
Embed.propTypes = {
  onSubmit: func.isRequired,
  onDismiss: func.isRequired
};