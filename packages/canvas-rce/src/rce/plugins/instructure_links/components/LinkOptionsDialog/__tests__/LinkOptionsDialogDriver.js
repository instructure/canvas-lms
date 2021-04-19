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
import {fireEvent, queryByLabelText, queryByTestId} from '@testing-library/dom'

export default class LinkOptionsDialogDriver {
  static find(op) {
    const label = op === 'create' ? 'Insert Link' : 'Edit Link'
    const $tray = queryByLabelText(document.body, label)
    if ($tray == null) {
      return null
    }
    return new LinkOptionsDialogDriver($tray)
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

  get $doneButton() {
    return [...this.$element.querySelectorAll('button,[role="button"]')].find(
      $button => $button.textContent.trim() === 'Done'
    )
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

  setText(text) {
    fireEvent.change(this.$textField, {target: {value: text}})
  }

  setLink(text) {
    fireEvent.change(this.$linkField, {target: {value: text}})
  }
}
