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
import React, { useState, useEffect } from 'react';
import { bool, func, number, shape, string } from 'prop-types';
import { Button, CloseButton } from '@instructure/ui-buttons';
import { Heading } from '@instructure/ui-heading';
import { Flex } from '@instructure/ui-flex';
import { Tray } from '@instructure/ui-tray';
import { CUSTOM, MIN_HEIGHT, MIN_WIDTH, MIN_PERCENTAGE, scaleToSize } from "../ImageEmbedOptions.js";
import formatMessage from "../../../../format-message.js";
import { useDimensionsState } from "../../shared/DimensionsInput/index.js";
import ImageOptionsForm from "../../shared/ImageOptionsForm.js";
import { getTrayHeight, isExternalUrl } from "../../shared/trayUtils.js";
import validateURL from "../../instructure_links/validateURL.js";
import UrlPanel from "../../shared/Upload/UrlPanel.js";
export default function ImageOptionsTray(props) {
  const imageOptions = props.imageOptions,
        onEntered = props.onEntered,
        onExited = props.onExited,
        onRequestClose = props.onRequestClose,
        onSave = props.onSave,
        open = props.open;
  const naturalHeight = imageOptions.naturalHeight,
        naturalWidth = imageOptions.naturalWidth,
        isLinked = imageOptions.isLinked;
  const currentHeight = imageOptions.appliedHeight || naturalHeight;
  const currentWidth = imageOptions.appliedWidth || naturalWidth;

  const _useState = useState(imageOptions.url),
        _useState2 = _slicedToArray(_useState, 2),
        url = _useState2[0],
        setUrl = _useState2[1];

  const _useState3 = useState(false),
        _useState4 = _slicedToArray(_useState3, 2),
        showUrlField = _useState4[0],
        setShowUrlField = _useState4[1];

  const _useState5 = useState(imageOptions.altText),
        _useState6 = _slicedToArray(_useState5, 2),
        altText = _useState6[0],
        setAltText = _useState6[1];

  const _useState7 = useState(imageOptions.isDecorativeImage),
        _useState8 = _slicedToArray(_useState7, 2),
        isDecorativeImage = _useState8[0],
        setIsDecorativeImage = _useState8[1];

  const _useState9 = useState('embed'),
        _useState10 = _slicedToArray(_useState9, 2),
        displayAs = _useState10[0],
        setDisplayAs = _useState10[1];

  const _useState11 = useState(imageOptions.imageSize),
        _useState12 = _slicedToArray(_useState11, 2),
        imageSize = _useState12[0],
        setImageSize = _useState12[1];

  const _useState13 = useState(currentHeight),
        _useState14 = _slicedToArray(_useState13, 2),
        imageHeight = _useState14[0],
        setImageHeight = _useState14[1];

  const _useState15 = useState(currentWidth),
        _useState16 = _slicedToArray(_useState15, 2),
        imageWidth = _useState16[0],
        setImageWidth = _useState16[1];

  const dimensionsState = useDimensionsState(imageOptions, {
    minHeight: MIN_HEIGHT,
    minWidth: MIN_WIDTH,
    minPercentage: MIN_PERCENTAGE
  });
  useEffect(() => {
    let isValidURL;

    try {
      isValidURL = validateURL(url);
    } catch (error) {
      isValidURL = false;
    } finally {
      setShowUrlField(isValidURL ? isExternalUrl(url) : true);
    }
  }, []);
  const messagesForSize = [];

  if (imageSize !== CUSTOM) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {
        height: imageHeight,
        width: imageWidth
      }),
      type: 'hint'
    });
  }

  const saveDisabled = url === '' || displayAs === 'embed' && (!isDecorativeImage && altText === '' || imageSize === CUSTOM && !(dimensionsState !== null && dimensionsState !== void 0 && dimensionsState.isValid));
  return /*#__PURE__*/React.createElement(Tray, {
    "data-mce-component": true,
    label: formatMessage('Image Options Tray'),
    onDismiss: onRequestClose,
    onEntered: onEntered,
    onExited: onExited,
    open: open,
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
  }, formatMessage('Image Options'))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(CloseButton, {
    placemet: "static",
    variant: "icon",
    onClick: onRequestClose
  }, formatMessage('Close'))))), /*#__PURE__*/React.createElement(Flex.Item, {
    as: "form",
    grow: true,
    margin: "none",
    shrink: true
  }, /*#__PURE__*/React.createElement(Flex, {
    justifyItems: "space-between",
    direction: "column",
    height: "100%"
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "column"
  }, showUrlField && /*#__PURE__*/React.createElement(Flex.Item, {
    padding: "small"
  }, /*#__PURE__*/React.createElement(UrlPanel, {
    fileUrl: url,
    setFileUrl: function (newUrl) {
      setUrl(newUrl);
    }
  })), /*#__PURE__*/React.createElement(ImageOptionsForm, {
    id: "image-options-form",
    imageSize: imageSize,
    displayAs: displayAs,
    isDecorativeImage: isDecorativeImage,
    altText: altText,
    isLinked: isLinked,
    dimensionsState: dimensionsState,
    handleAltTextChange: function (event) {
      setAltText(event.target.value);
    },
    handleIsDecorativeChange: function (event) {
      setIsDecorativeImage(event.target.checked);
    },
    handleDisplayAsChange: function (event) {
      setDisplayAs(event.target.value);
    },
    handleImageSizeChange: function (event, selectedOption) {
      setImageSize(selectedOption.value);

      if (selectedOption.value === CUSTOM) {
        setImageHeight(currentHeight);
        setImageWidth(currentWidth);
      } else {
        const _scaleToSize = scaleToSize(selectedOption.value, naturalWidth, naturalHeight),
              height = _scaleToSize.height,
              width = _scaleToSize.width;

        setImageHeight(height);
        setImageWidth(width);
      }
    },
    messagesForSize: messagesForSize
  })), /*#__PURE__*/React.createElement(Flex.Item, {
    background: "secondary",
    borderWidth: "small none none none",
    padding: "small medium",
    textAlign: "end"
  }, /*#__PURE__*/React.createElement(Button, {
    disabled: saveDisabled,
    onClick: function (event) {
      event.preventDefault();
      const savedAltText = isDecorativeImage ? '' : altText;
      let appliedHeight = imageHeight;
      let appliedWidth = imageWidth;

      if (imageSize === CUSTOM) {
        if (dimensionsState.usePercentageUnits) {
          appliedHeight = `${dimensionsState.percentage}%`;
          appliedWidth = `${dimensionsState.percentage}%`;
        } else {
          appliedHeight = dimensionsState.height;
          appliedWidth = dimensionsState.width;
        }
      }

      onSave({
        url,
        altText: savedAltText,
        appliedHeight,
        appliedWidth,
        displayAs,
        isDecorativeImage
      });
    },
    variant: "primary"
  }, formatMessage('Done')))))));
}
ImageOptionsTray.propTypes = {
  imageOptions: shape({
    altText: string.isRequired,
    appliedHeight: number,
    appliedWidth: number,
    isDecorativeImage: bool.isRequired,
    isLinked: bool,
    naturalHeight: number.isRequired,
    naturalWidth: number.isRequired
  }).isRequired,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
};
ImageOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
};