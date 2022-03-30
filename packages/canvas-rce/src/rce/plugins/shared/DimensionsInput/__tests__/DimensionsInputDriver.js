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

import NumberInputDriver from './NumberInputDriver'
import {queryByLabelText, getByTestId} from '@testing-library/react'

export default class DimensionsInputDriver {
  static find($parent) {
    const $fieldset = [...$parent.querySelectorAll('fieldset')].find($element =>
      $element.textContent.includes('Dimensions')
    )

    if ($fieldset == null) {
      return null
    }

    return new DimensionsInputDriver($fieldset)
  }

  constructor($parent) {
    this.$typeSelector = $parent.firstChild.firstChild
    this.$dimensionsInput = $parent.firstChild.lastChild
  }

  get width() {
    const $container = getByTestId(this.$dimensionsInput, 'input-number-container')
    return NumberInputDriver.findByLabelText('Width', $container)
  }

  get height() {
    const $container = getByTestId(this.$dimensionsInput, 'input-number-container')
    return NumberInputDriver.findByLabelText('Height', $container)
  }

  get percentage() {
    const $container = getByTestId(this.$dimensionsInput, 'input-number-container')
    return NumberInputDriver.findByLabelText('Percentage', $container)
  }

  get pixelsRadioButton() {
    const $parent = getByTestId(this.$typeSelector, 'dimension-type')
    return queryByLabelText($parent, 'Pixels', {exact: false})
  }

  get percentageRadioButton() {
    const $parent = getByTestId(this.$typeSelector, 'dimension-type')
    return queryByLabelText($parent, 'Percentage', {exact: false})
  }

  get messageTexts() {
    const messageContainer = this.$dimensionsInput.querySelector(
      'fieldset legend span:last-child span:first-child'
    )
    return [...messageContainer.querySelectorAll('span')].map($message =>
      $message.textContent.trim()
    )
  }
}
