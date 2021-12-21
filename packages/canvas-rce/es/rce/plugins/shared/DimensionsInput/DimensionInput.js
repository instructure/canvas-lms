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
import { func, shape, string } from 'prop-types';
import { ScreenReaderContent } from '@instructure/ui-a11y-content';
import { NumberInput } from '@instructure/ui-number-input';
export default function DimensionInput(props) {
  const dimensionState = props.dimensionState,
        label = props.label;
  const addOffset = dimensionState.addOffset,
        inputValue = dimensionState.inputValue,
        setInputValue = dimensionState.setInputValue;
  return /*#__PURE__*/React.createElement(NumberInput, {
    renderLabel: /*#__PURE__*/React.createElement(ScreenReaderContent, null, label),
    onChange: function (_event, value) {
      setInputValue(value);
    },
    onDecrement: function () {
      addOffset(-1);
    },
    onIncrement: function () {
      addOffset(1);
    },
    isRequired: true,
    showArrows: false,
    value: inputValue
  });
}
DimensionInput.propTypes = {
  dimensionState: shape({
    addOffset: func.isRequired,
    inputValue: string.isRequired,
    setInputValue: func.isRequired
  }),
  label: string.isRequired
};