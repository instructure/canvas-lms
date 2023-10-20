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

import React from 'react'
import PropTypes from 'prop-types'
import {NumberInput} from '@instructure/ui-number-input'
import {useDebouncedNumericValue} from './useDebouncedNumericValue'
import formatMessage from '../../../../../format-message'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export const CustomNumberInput = ({
  value,
  parseValueCallback,
  processValueCallback,
  formatValueCallback,
  placeholder,
  onChange,
}) => {
  const [inputValue, digestCurrentValue, digestNewValue, hasError] = useDebouncedNumericValue({
    value,
    parseValueCallback,
    processValueCallback,
    formatValueCallback,
    onChange,
  })
  const handleChange = (event, newValue) => digestNewValue(newValue.trim())
  const handleBlur = () => digestCurrentValue()
  const handleIncrement = () => onChange(processValueCallback(value + 1))
  const handleDecrement = () => onChange(processValueCallback(value - 1))
  const messages = hasError ? [{text: formatMessage('Invalid entry.'), type: 'error'}] : []

  return (
    <NumberInput
      value={inputValue}
      onChange={handleChange}
      onBlur={handleBlur}
      onIncrement={handleIncrement}
      onDecrement={handleDecrement}
      placeholder={placeholder}
      showArrows={false}
      messages={messages}
      renderLabel={<ScreenReaderContent>{placeholder}</ScreenReaderContent>}
      interaction="enabled"
      width="4.5rem"
    />
  )
}

CustomNumberInput.propTypes = {
  value: PropTypes.number.isRequired,
  onChange: PropTypes.func.isRequired,
  // Parses a raw string value and returns a number. Ex. "90º" -> 90
  parseValueCallback: PropTypes.func,
  // Processes a number and returns a handled number (for example thresholds). Ex. 370 -> 10
  processValueCallback: PropTypes.func,
  // Formats a number and returns a formatted string number. Ex. 90 -> "90º"
  formatValueCallback: PropTypes.func,
  placeholder: PropTypes.string,
}

CustomNumberInput.defaultProps = {
  parseValueCallback: value => value,
  processValueCallback: value => value,
  formatValueCallback: value => value,
  placeholder: '',
}
