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

import {
  fireEvent,
  getAllByText,
  getByLabelText,
  queryByLabelText,
  queryByTestId,
  waitFor,
} from '@testing-library/dom'

function getSizeOptions($sizeSelect) {
  const controlledId = $sizeSelect.getAttribute('aria-controls')
  const $listBox = document.getElementById(controlledId)
  if ($listBox === null) {
    throw new Error('Size options not yet open')
  }
  return [...$listBox.querySelectorAll('[role="option"]')]
}

export default class VideoOptionsTrayDriver {
  static find() {
    const $tray = queryByLabelText(document.body, 'Video Options Tray')
    if ($tray == null) {
      return null
    }
    return new VideoOptionsTrayDriver($tray)
  }

  constructor($element) {
    this.$element = $element
  }

  get label() {
    return this.$element.getAttribute('aria-label')
  }

  get $titleTextField() {
    return this.$element.querySelector('textarea')
  }

  get $displayAsField() {
    return getAllByText(this.$element, 'Display Options')[0].closest('fieldset')
  }

  get $sizeSelect() {
    return getByLabelText(this.$element, /Size.*/)
  }

  get $doneButton() {
    return [...this.$element.querySelectorAll('button,[role="button"]')].find(
      $button => $button.textContent.trim() === 'Done'
    )
  }

  get $closedCaptionPanel() {
    return queryByTestId(this.$element, 'ClosedCaptionPanel')
  }

  get titleText() {
    return this.$titleTextField.value
  }

  get titleTextDisabled() {
    return this.$titleTextField.disabled
  }

  get displayAs() {
    return this.$displayAsField.querySelector('input[type="radio"]:checked').value
  }

  get size() {
    return this.$sizeSelect.value
  }

  get doneButtonDisabled() {
    return this.$doneButton.disabled
  }

  setTitleText(titleText) {
    fireEvent.change(this.$titleTextField, {target: {value: titleText}})
  }

  setDisplayAs(value) {
    const $input = this.$displayAsField.querySelector(`input[type="radio"][value="${value}"]`)
    $input.click()
  }

  async setSize(sizeText) {
    this.$sizeSelect.click()
    await waitFor(() => getSizeOptions(this.$sizeSelect))
    const $options = getSizeOptions(this.$sizeSelect)
    $options.find($option => $option.textContent.trim().includes(sizeText)).click()
  }
}
