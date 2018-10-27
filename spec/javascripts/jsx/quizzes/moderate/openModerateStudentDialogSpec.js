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

import openModerateStudentDialog from 'jsx/quizzes/moderate/openModerateStudentDialog'
import $ from 'jquery'

let $fixture = null
QUnit.module('openModerateStudentDialog', {
  setup() {
    $fixture = $('#fixtures').html(`
      <div id='parent'>
         <div id='moderate_student_dialog'>   
          </div>               
          <a class='ui-dialog-titlebar-close' href='#'>
          </a>                                           
          </div>                                         
        </div>`)
  },

  teardown() {
    $('#fixtures').empty()
  }
})

test('is a function', () => {
  ok(typeof openModerateStudentDialog === 'function')
})

test('focues on close button when opened', () => {
  const dialog = openModerateStudentDialog($('#moderate_student_dialog'), 500)
  const focusButton = dialog.parent().find('.ui-dialog-titlebar-close')[0]
  ok(focusButton === document.activeElement)
})
