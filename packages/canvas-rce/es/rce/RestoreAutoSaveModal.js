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
import { bool, func, string } from 'prop-types';
import { Alert } from '@instructure/ui-alerts';
import { Heading } from '@instructure/ui-heading';
import { Modal } from '@instructure/ui-modal';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { ToggleGroup } from '@instructure/ui-toggle-details';
import { View } from '@instructure/ui-view';
import formatMessage from "../format-message.js";
export default function RestoreAutoSaveModal(props) {
  const _useState = useState(false),
        _useState2 = _slicedToArray(_useState, 2),
        previewExpanded = _useState2[0],
        setPreviewExpanded = _useState2[1];

  return /*#__PURE__*/React.createElement(Modal, {
    "data-testid": "RCE_RestoreAutoSaveModal",
    "data-mce-component": true,
    label: formatMessage('Restore auto-save?'),
    open: props.open,
    shouldCloseOnDocumentClick: false,
    shouldReturnFocus: true,
    size: "medium",
    onDismiss: props.onNo
  }, /*#__PURE__*/React.createElement(Modal.Header, null, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "end",
    offset: "medium",
    variant: "icon",
    onClick: props.onNo
  }, formatMessage('Close')), /*#__PURE__*/React.createElement(Heading, null, formatMessage('Found auto-saved content'))), /*#__PURE__*/React.createElement(Modal.Body, null, /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "small"
  }, /*#__PURE__*/React.createElement(Alert, {
    variant: "info",
    margin: "none"
  }, formatMessage('Auto-saved content exists. Would you like to load the auto-saved content instead?'))), /*#__PURE__*/React.createElement(ToggleGroup, {
    summary: formatMessage('Preview'),
    toggleLabel: () => previewExpanded ? formatMessage('Click to hide preview') : formatMessage('Click to show preview'),
    onToggle: (_e, expanded) => {
      setPreviewExpanded(expanded);
    }
  }, /*#__PURE__*/React.createElement(View, {
    as: "div",
    dangerouslySetInnerHTML: {
      __html: props.savedContent
    },
    padding: "0 x-small",
    overflowX: "auto"
  }))), /*#__PURE__*/React.createElement(Modal.Footer, null, /*#__PURE__*/React.createElement(Button, {
    margin: "0 x-small",
    onClick: props.onNo
  }, formatMessage('No')), "\xA0", /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    onClick: props.onYes
  }, formatMessage('Yes'))));
}
RestoreAutoSaveModal.propTypes = {
  savedContent: string,
  open: bool.isRequired,
  onNo: func.isRequired,
  onYes: func.isRequired
};
RestoreAutoSaveModal.defaultProps = {
  savedContent: ''
};