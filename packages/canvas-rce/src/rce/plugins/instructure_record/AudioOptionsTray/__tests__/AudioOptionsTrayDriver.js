/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {queryAllByLabelText, queryByTestId} from '@testing-library/dom'

export default class AudioOptionsTrayDriver {
  static find() {
    const $tray = queryAllByLabelText(document.body, 'Audio Options Tray')
    if ($tray.length === 0) {
      return null
    }
    return new AudioOptionsTrayDriver($tray[0])
  }

  constructor($element) {
    this.$element = $element
  }

  get label() {
    return this.$element.getAttribute('aria-label')
  }

  get $doneButton() {
    return [...this.$element.querySelectorAll('button,[role="button"]')].find(
      $button => $button.textContent.trim() === 'Done'
    )
  }

  get $closedCaptionPanel() {
    return queryByTestId(this.$element, 'ClosedCaptionPanel')
  }

  get doneButtonDisabled() {
    return this.$doneButton.disabled
  }
}
