/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate' // required
import openModerateStudentDialog from '../openModerateStudentDialog'

describe('openModerateStudentDialog', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id='fixtures'>
        <div id='parent'>
          <div id='moderate_student_dialog'></div>
          <a class='ui-dialog-titlebar-close' href='#'></a>
        </div>
      </div>`
  })

  afterEach(() => {
    $('#fixtures').empty()
  })

  test('focuses on close button when opened', () => {
    const dialog = openModerateStudentDialog($('#moderate_student_dialog'), 500)
    const focusButton = dialog.parent().find('.ui-dialog-titlebar-close')[0]
    expect(focusButton).toBe(document.activeElement)
    focusButton.click()
    $(dialog).remove()
  })
})
