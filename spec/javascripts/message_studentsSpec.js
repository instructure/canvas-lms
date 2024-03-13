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
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import messageStudents from 'message_students'

QUnit.module('MessageStudents dialog', hooks => {
  let fixtures
  let settings

  function selectedStudentNames() {
    // Ignore the "template" entry, which is still in the list
    const $studentNames = document.querySelectorAll(
      '#message_students_dialog .student_list .student:not(.blank) .name'
    )
    return [...$studentNames].map(nameElement => nameElement.innerText)
  }

  hooks.beforeEach(() => {
    settings = {
      context_code: 'Z',
      options: [],
      points_possible: 0,
      students: [
        {name: 'Boudica', sortableName: 'Boudica', id: '1', score: 50},
        {name: 'Vercingetorix', sortableName: 'Vercingetorix', id: '2', score: 40},
        {name: 'Ariovistus', sortableName: 'Ariovistus', id: '10', score: 53},
        {name: 'Gaius Julius Caesar', sortableName: 'Caesar, Gaius Julius', id: '20', score: 48},
      ],
      title: 'My Great Course!!!',
    }

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

          <ul class="student_list">
            <li class="student blank">
              <span class="name">&nbsp;</span>
              <span class="score">&nbsp;</span>
              <button class="remove-button Button Button--icon-action"><i class="icon-x"></i></button>
            </li>
          </ul>
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

  test('renders the students alphabetically by sortable name', () => {
    messageStudents(settings)
    deepEqual(selectedStudentNames(), [
      'Ariovistus',
      'Boudica',
      'Gaius Julius Caesar',
      'Vercingetorix',
    ])
  })

  test('includes users with IDs higher than Javascript numbers can handle', () => {
    const crossShardStudent = {
      id: String(Number.MAX_SAFE_INTEGER + 1),
      name: 'Student From Another World',
      score: 48,
      sortableName: 'World, Student From Another',
    }
    settings.students.push(crossShardStudent)

    messageStudents(settings)
    deepEqual(selectedStudentNames(), [
      'Ariovistus',
      'Boudica',
      'Gaius Julius Caesar',
      'Vercingetorix',
      'Student From Another World',
    ])
  })
})
