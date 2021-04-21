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

import {fireEvent} from '@testing-library/dom'

export default class GradeInputDriver {
  static find($parent = document.body) {
    const $input = $parent.querySelector('#grade-detail-tray--grade-input')

    if ($input == null) {
      return null
    }

    return new GradeInputDriver($input.closest('label'))
  }

  constructor($element) {
    this.$element = $element
  }

  get $input() {
    return this.$element.querySelector('input[type="text"]')
  }

  get $optionsList() {
    const optionsListId = this.$input.getAttribute('aria-controls')
    return document.getElementById(optionsListId)
  }

  get $options() {
    return [...this.$optionsList.querySelectorAll('[role="option"]')]
  }

  get value() {
    return this.$input.value
  }

  get optionLabels() {
    return this.$options.map($option => $option.textContent.trim())
  }

  get activeItemLabel() {
    const activeDescendantId = this.$input.getAttribute('aria-activedescendant')
    const $activeDescendant = this.$options.find($option => $option.id === activeDescendantId)
    return $activeDescendant != null ? $activeDescendant.textContent.trim() : null
  }

  get isExpanded() {
    return this.$input.getAttribute('aria-expanded') === 'true'
  }

  get inputIsDisabled() {
    return this.$input.disabled
  }

  get optionsAreDisabled() {
    return this.$options.some($option => $option.getAttribute('aria-disabled') === 'true')
  }

  get isReadOnly() {
    return this.$input.readOnly
  }

  get labelText() {
    return this.$element.textContent.trim()
  }

  get $messages() {
    const describedById = this.$input.getAttribute('aria-describedby')
    const $messageContainer = document.querySelector(`#${describedById}`)
    return $messageContainer ? [...$messageContainer.children] : []
  }

  get messageTexts() {
    return this.$messages.map($message => $message.textContent.trim())
  }

  clickToExpand() {
    this.$input.click()
  }

  clickToSelectOption(optionLabel) {
    this.getOptionWithLabel(optionLabel).click()
  }

  getOptionWithLabel(optionLabel) {
    return this.$options.find($option => $option.textContent.trim() === optionLabel)
  }

  blurInput() {
    fireEvent.blur(this.$input)
  }

  inputValue(value) {
    fireEvent.input(this.$input, {target: {value}})
  }

  keyDown(keyCode) {
    fireEvent.keyDown(document.activeElement, {keyCode})
  }
}
