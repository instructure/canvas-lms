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
  getByLabelText,
  getAllByText,
  queryByLabelText,
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

export default class ImageOptionsTrayDriver {
  static find() {
    const $tray = queryByLabelText(document.body, 'Image Options Tray')
    if ($tray !== null) {
      return new ImageOptionsTrayDriver($tray)
    }

    const $trayForIcons = queryByLabelText(document.body, 'Icon Options Tray')
    if ($trayForIcons !== null) {
      return new ImageOptionsTrayDriver($trayForIcons)
    }

    return null
  }

  constructor($element) {
    this.$element = $element
  }

  get label() {
    return this.$element.getAttribute('aria-label')
  }

  get $urlField() {
    return this.$element.querySelector('input[name="file-url"]')
  }

  get $altTextField() {
    return this.$element.querySelector('textarea')
  }

  get $isDecorativeCheckbox() {
    return getByLabelText(this.$element, 'Decorative Image', {exact: false})
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

  get urlText() {
    return this.$urlField.value
  }

  get altText() {
    return this.$altTextField.value
  }

  get altTextDisabled() {
    return this.$altTextField.disabled
  }

  get isDecorativeImage() {
    return this.$isDecorativeCheckbox.checked
  }

  get isDecorativeImageDisabled() {
    return this.$isDecorativeCheckbox.disabled
  }

  get displayAs() {
    return this.$displayAsField.querySelector('input[type="radio"]:checked').value
  }

  get isDisplayAsDisabled() {
    return this.$displayAsField.querySelectorAll('input[disabled]').length === 2
  }

  get size() {
    return this.$sizeSelect.value
  }

  get doneButtonDisabled() {
    return this.$doneButton.disabled
  }

  setAltText(altText) {
    fireEvent.change(this.$altTextField, {target: {value: altText}})
  }

  setIsDecorativeImage(isDecorativeImage) {
    if (this.isDecorativeImage !== isDecorativeImage) {
      this.$isDecorativeCheckbox.click()
    }
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

  async setUrl(url) {
    fireEvent.change(this.$urlField, {target: {value: url}})
  }
}
