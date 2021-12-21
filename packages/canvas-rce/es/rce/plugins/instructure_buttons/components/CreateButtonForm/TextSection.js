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
import React from 'react';
import { Flex } from '@instructure/ui-flex';
import { TextInput } from '@instructure/ui-text-input';
import { SimpleSelect } from '@instructure/ui-simple-select';
import { ColorInput } from "../../../shared/ColorInput.js";
import formatMessage from "../../../../../format-message.js";
import { Group } from "./Group.js";
import { MAX_TOTAL_TEXT_CHARS } from "../../svg/constants.js";
const TEXT_SIZES = ['small', 'medium', 'large', 'x-large'];
const TEXT_POSITIONS = ['middle', 'bottom-third', 'below'];

const getTextSection = () => document.querySelector('#buttons-tray-text-section');

export const TextSection = ({
  settings,
  onChange
}) => /*#__PURE__*/React.createElement(Group, {
  as: "section",
  defaultExpanded: true,
  summary: formatMessage('Text')
}, /*#__PURE__*/React.createElement(Flex, {
  as: "section",
  justifyItems: "space-between",
  direction: "column",
  id: "buttons-tray-text-section"
}, /*#__PURE__*/React.createElement(Flex.Item, {
  padding: "small"
}, /*#__PURE__*/React.createElement(TextInput, {
  id: "button-text",
  renderLabel: formatMessage('Text'),
  onChange: e => {
    const text = e.target.value;
    if (text.length <= MAX_TOTAL_TEXT_CHARS) onChange({
      text
    });
  },
  value: settings.text,
  messages: [{
    text: `${settings.text.length}/${MAX_TOTAL_TEXT_CHARS}`,
    type: 'hint'
  }]
})), /*#__PURE__*/React.createElement(Flex.Item, {
  padding: "small"
}, /*#__PURE__*/React.createElement(SimpleSelect, {
  assistiveText: formatMessage('Use arrow keys to select a text size.'),
  id: "button-text-size",
  onChange: (e, option) => onChange({
    textSize: option.value
  }),
  renderLabel: formatMessage('Text Size'),
  value: settings.textSize
}, TEXT_SIZES.map(size => /*#__PURE__*/React.createElement(SimpleSelect.Option, {
  id: `text-size-${size}`,
  key: `text-size-${size}`,
  value: size
}, TEXT_SIZE_DESCRIPTION[size] || '')))), /*#__PURE__*/React.createElement(Flex.Item, {
  padding: "small"
}, /*#__PURE__*/React.createElement(ColorInput, {
  color: settings.textColor,
  label: formatMessage('Text Color'),
  id: "button-text-color",
  onChange: textColor => onChange({
    textColor
  }),
  popoverMountNode: getTextSection
})), /*#__PURE__*/React.createElement(Flex.Item, {
  padding: "small"
}, /*#__PURE__*/React.createElement(ColorInput, {
  color: settings.textBackgroundColor,
  label: formatMessage('Text Background Color'),
  id: "button-text-background-color",
  onChange: textBackgroundColor => onChange({
    textBackgroundColor
  }),
  popoverMountNode: getTextSection
})), /*#__PURE__*/React.createElement(Flex.Item, {
  padding: "small"
}, /*#__PURE__*/React.createElement(SimpleSelect, {
  assistiveText: formatMessage('Use arrow keys to select a text position.'),
  id: "button-text-position",
  onChange: (e, option) => onChange({
    textPosition: option.value
  }),
  renderLabel: formatMessage('Text Position'),
  value: settings.textPosition
}, TEXT_POSITIONS.map(position => /*#__PURE__*/React.createElement(SimpleSelect.Option, {
  id: `text-position-${position}`,
  key: `text-position-${position}`,
  value: position
}, TEXT_POSITION_DESCRIPTION[position] || ''))))));
const TEXT_SIZE_DESCRIPTION = {
  small: formatMessage('Small'),
  medium: formatMessage('Medium'),
  large: formatMessage('Large'),
  'x-large': formatMessage('Extra Large')
};
const TEXT_POSITION_DESCRIPTION = {
  middle: formatMessage('Middle'),
  'bottom-third': formatMessage('Bottom Third'),
  below: formatMessage('Below')
};