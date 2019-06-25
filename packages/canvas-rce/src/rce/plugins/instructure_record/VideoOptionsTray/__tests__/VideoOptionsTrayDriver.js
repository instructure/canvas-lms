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

import {getByLabelText, queryByLabelText, wait} from 'dom-testing-library'

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

  get $sizeSelect() {
    return getByLabelText(this.$element, 'Size')
  }

  get $doneButton() {
    return [...this.$element.querySelectorAll('button,[role="button"]')].find(
      $button => $button.textContent.trim() === 'Done'
    )
  }

  get size() {
    return this.$sizeSelect.value
  }

  get doneButtonDisabled() {
    return this.$doneButton.disabled
  }

  async setSize(sizeText) {
    this.$sizeSelect.click()
    await wait(() => getSizeOptions(this.$sizeSelect))
    const $options = getSizeOptions(this.$sizeSelect)
    $options.find($option => $option.textContent.trim().includes(sizeText)).click()
  }
}
