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
import { SimpleSelect } from '@instructure/ui-simple-select';
import { Flex } from '@instructure/ui-flex';
import ImageCropperPreview from "./ImageCropperPreview.js";
import formatMessage from "../../../../../../format-message.js";
const SHAPE_OPTIONS = [{
  id: 'square',
  label: formatMessage('Square')
}, {
  id: 'circle',
  label: formatMessage('Circle')
}, {
  id: 'triangle',
  label: formatMessage('Triangle')
}, {
  id: 'diamond',
  label: formatMessage('Diamond')
}, {
  id: 'pentagon',
  label: formatMessage('Pentagon')
}, {
  id: 'hexagon',
  label: formatMessage('Hexagon')
}, {
  id: 'octagon',
  label: formatMessage('Octagon')
}, {
  id: 'star',
  label: formatMessage('Star')
}];
export const ImageCropper = () => {
  const _useState = useState('square'),
        _useState2 = _slicedToArray(_useState, 2),
        selectedShape = _useState2[0],
        setSelectedShape = _useState2[1];

  return /*#__PURE__*/React.createElement(Flex, {
    direction: "column",
    margin: "none"
  }, /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "none none small"
  }, /*#__PURE__*/React.createElement(SimpleSelect, {
    isInline: true,
    assistiveText: formatMessage('Select crop shape'),
    value: selectedShape,
    onChange: (event, {
      id
    }) => setSelectedShape(id)
  }, SHAPE_OPTIONS.map(option => /*#__PURE__*/React.createElement(SimpleSelect.Option, {
    key: option.id,
    id: option.id,
    value: option.id
  }, option.label)))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(ImageCropperPreview, {
    shape: selectedShape
  })));
};