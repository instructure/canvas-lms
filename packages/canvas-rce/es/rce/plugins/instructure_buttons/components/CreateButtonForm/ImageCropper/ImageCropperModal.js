/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import PropTypes from 'prop-types';
import { Modal } from '@instructure/ui-modal';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { ImageCropper } from "./ImageCropper.js";
import formatMessage from "../../../../../../format-message.js";
export const ImageCropperModal = ({
  open,
  onClose,
  image
}) => {
  return /*#__PURE__*/React.createElement(Modal, {
    size: "large",
    open: open,
    onDismiss: onClose,
    shouldCloseOnDocumentClick: false
  }, /*#__PURE__*/React.createElement(Modal.Header, null, /*#__PURE__*/React.createElement(CloseButton, {
    placement: "end",
    offset: "small",
    onClick: onClose,
    screenReaderLabel: "Close"
  }), /*#__PURE__*/React.createElement(Heading, null, formatMessage('Crop Image'))), /*#__PURE__*/React.createElement(Modal.Body, null, /*#__PURE__*/React.createElement(ImageCropper, {
    image: image
  })), /*#__PURE__*/React.createElement(Modal.Footer, null, /*#__PURE__*/React.createElement(Button, {
    onClick: onClose,
    margin: "0 x-small 0 0"
  }, formatMessage('Cancel')), /*#__PURE__*/React.createElement(Button, {
    color: "primary",
    type: "submit"
  }, formatMessage('Save'))));
};
ImageCropperModal.propTypes = {
  open: PropTypes.bool,
  onClose: PropTypes.func,
  image: PropTypes.string
};