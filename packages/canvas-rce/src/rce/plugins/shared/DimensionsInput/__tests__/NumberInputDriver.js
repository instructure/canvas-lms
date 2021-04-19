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

import {queryByLabelText, fireEvent} from '@testing-library/react'

export default class NumberInputDriver {
  static findByLabelText(labelText, $parent) {
    const $input = queryByLabelText($parent, labelText, {exact: false})

    if ($input == null) {
      return null
    }

    return new NumberInputDriver($input)
  }

  constructor($element) {
    this.$element = $element
  }

  get label() {
    return null
  }

  get value() {
    return this.$element.value
  }

  get messageTexts() {
    const [$label] = this.$element.labels
    const messagesId = $label.getAttribute('aria-describedby')
    if (messagesId == null) {
      return []
    }

    return [...$label.querySelectorAll(`#${messagesId} > *`)].map($message =>
      $message.textContent.trim()
    )
  }

  setValue(value) {
    fireEvent.change(this.$element, {target: {value}})
  }

  decrement() {
    // Down Arrow
    fireEvent.keyDown(this.$element, {keyCode: 40})
  }

  increment() {
    // Up Arrow
    fireEvent.keyDown(this.$element, {keyCode: 38})
  }
}
