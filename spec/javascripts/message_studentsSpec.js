/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import fakeENV from 'helpers/fakeENV'
import messageStudents from 'message_students'

QUnit.module('MessageStudents dialog', hooks => {
  let fixtures
  const settings = {
    context_code: 'Z',
    options: [],
    points_possible: 0,
    students: [],
    title: 'My Great Course!!!'
  }

  hooks.beforeEach(() => {
    fixtures = $('#fixtures')
    fixtures.append(`
      <div id="message_students_dialog">
        <form id="message_assignment_recipients">
          <span id="message_students_dialog_label"></span>
          <div id="body">
            <select class="message_types"></select>
          </div>

          <div class="button-container">
            <button class="Button cancel_button">Cancel</button>
            <button class="Button Button--primary send_button">Send Message</button>
          </div>
        </form>
      </div>
    `)
  })

  hooks.afterEach(() => {
    fakeENV.teardown()
    fixtures.empty()
    $('.ui-dialog').remove()
    $('#message_students_dialog').remove()
  })

  test('sets the role of the containing dialog to "dialog" when opened', () => {
    messageStudents(settings)
    strictEqual($('.ui-dialog').attr('role'), 'dialog')
  })

  test('sets the content of the dialog label to the dialog title when opened', () => {
    messageStudents(settings)
    strictEqual($('.ui-dialog').attr('aria-label'), 'Message Students for My Great Course!!!')
  })

  test('removes the role of the containing dialog when closed', () => {
    messageStudents(settings)
    $('#message_students_dialog').dialog('close')
    strictEqual($('.ui-dialog').attr('role'), undefined)
  })

  test('clears the content of the dialog label when closed', () => {
    messageStudents(settings)
    $('#message_students_dialog').dialog('close')
    strictEqual($('.ui-dialog').attr('aria-label'), undefined)
  })
})
