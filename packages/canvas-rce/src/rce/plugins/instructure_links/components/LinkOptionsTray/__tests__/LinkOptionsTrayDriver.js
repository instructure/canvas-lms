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
  getAllByText,
  fireEvent,
  queryByLabelText,
  queryByTestId,
  queryHelpers,
} from '@testing-library/dom'

export default class LinkOptionsTrayDriver {
  static find() {
    const $tray = queryByLabelText(document.body, 'Link Options')
    if ($tray == null) {
      return null
    }
    return new LinkOptionsTrayDriver($tray)
  }

  constructor($element) {
    this.$element = $element
  }

  get label() {
    return this.$element.getAttribute('aria-label')
  }

  get $textField() {
    return queryByLabelText(document.body, 'Text', {selector: 'input'})
  }

  get $linkField() {
    return queryByLabelText(document.body, 'Link', {selector: 'input'})
  }

  get $displayAsField() {
    return getAllByText(this.$element, 'Display Options')[0].closest('fieldset')
  }

  get $previewCheckbox() {
    return queryHelpers.queryByAttribute('name', this.$element, 'auto-preview')
  }

  get $doneButton() {
    return [...this.$element.querySelectorAll('button,[role="button"]')].find(
      $button => $button.textContent.trim() === 'Done'
    )
  }

  get $previewOptionOverlayRadioInput() {
    return queryHelpers.queryByAttribute('value', this.$element, 'overlay')
  }

  get $previewOptionInlineRadioInput() {
    return queryHelpers.queryByAttribute('value', this.$element, 'inline')
  }

  get $previewOptionDisableRadioInput() {
    return queryHelpers.queryByAttribute('value', this.$element, 'disable')
  }

  get doneButtonIsDisabled() {
    return this.$doneButton.getAttribute('disabled') !== null
  }

  get $errorMessage() {
    return queryByTestId(this.$element, 'url-error')
  }

  get text() {
    return this.$textField.value
  }

  get link() {
    return this.$linkField.value
  }

  get autoPreview() {
    return this.$previewCheckbox.checked
  }

  get previewOption() {
    const $overlay = this.$previewOptionOverlayRadioInput
    const $inline = this.$previewOptionInlineRadioInput
    const $disable = this.$previewOptionDisableRadioInput
    if ($overlay.checked) return 'overlay'
    if ($inline.checked) return 'inline'
    if ($disable.checked) return 'disable'
    throw new Error('something is wrong')
  }

  setText(text) {
    fireEvent.change(this.$textField, {target: {value: text}})
  }

  setLink(text) {
    fireEvent.change(this.$linkField, {target: {value: text}})
  }

  setAutoPreview(value) {
    const $input = this.$previewCheckbox
    if ($input.checked !== value) {
      $input.click()
    }
  }

  setPreviewOption(value) {
    queryHelpers.queryByAttribute('value', this.$element, value).click()
  }
}
