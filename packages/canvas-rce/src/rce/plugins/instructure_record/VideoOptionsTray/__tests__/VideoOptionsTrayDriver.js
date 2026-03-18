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
  getByText,
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

  get $titleInput() {
    return this.$element.querySelector('input[placeholder="Enter a media title"]')
  }

  get $titleTextField() {
    return this.$titleInput
  }

  get $displayAsField() {
    return getAllByText(this.$element, 'Display Options')[0].closest('fieldset')
  }

  get $sizeSelect() {
    return getByLabelText(this.$element, /Size.*/)
  }

  get $doneButton() {
    return [...this.$element.querySelectorAll('button,[role="button"]')].find(
      $button => $button.textContent.trim() === 'Done',
    )
  }

  get $closedCaptionPanel() {
    return queryByTestId(this.$element, 'ClosedCaptionPanel')
  }

  get titleText() {
    return this.$titleInput.value
  }

  get titleTextDisabled() {
    return this.$titleInput.disabled
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

  get $manualCaptionsAddNewButton() {
    return getByText(this.$closedCaptionPanel, /Add new/i)
  }

  get $manualCaptionsLanguageSelect() {
    return getByLabelText(this.$closedCaptionPanel, /Select Language/i)
  }

  get $manualCaptionsFileInput() {
    return this.$closedCaptionPanel.querySelector('input[type="file"]')
  }

  get $manualCaptionsCancelButton() {
    return getByText(this.$closedCaptionPanel, 'Cancel')
  }

  get $manualCaptionsUploadButton() {
    return getByText(this.$closedCaptionPanel, 'Upload')
  }

  get $automaticCaptionsAddNewButton() {
    return getByText(this.$closedCaptionPanel, 'Request')
  }

  get $automaticCaptionsLanguageSelect() {
    return getByLabelText(this.$closedCaptionPanel, /Select Language/i)
  }

  get $automaticCaptionsCancelButton() {
    return getByText(this.$closedCaptionPanel, 'Cancel')
  }

  get $automaticCaptionsRequestButton() {
    return getByText(this.$closedCaptionPanel, 'Request')
  }

  setTitleText(titleText) {
    fireEvent.change(this.$titleInput, {target: {value: titleText}})
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

  messageText() {
    const message = queryByTestId(this.$element, 'message')
    return message.textContent
  }
}
