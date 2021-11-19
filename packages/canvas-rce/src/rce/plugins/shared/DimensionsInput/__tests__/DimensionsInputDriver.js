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

  constructor($element) {
    this.$element = $element
  }

  get width() {
    return NumberInputDriver.findByLabelText('Width', this.$element)
  }

  get height() {
    return NumberInputDriver.findByLabelText('Height', this.$element)
  }

  get messageTexts() {
    const messagesId = this.$element.getAttribute('aria-describedby')
    if (messagesId == null) {
      return []
    }

    return [...this.$element.querySelectorAll(`#${messagesId} > *`)].map($message =>
      $message.textContent.trim()
    )
  }
}
