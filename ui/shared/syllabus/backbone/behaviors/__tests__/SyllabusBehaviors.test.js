/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import SyllabusBehaviors from '../SyllabusBehaviors'
import Sidebar from '@canvas/rce/Sidebar'
import editorUtils from '@canvas/rce/editorUtils'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import $ from 'jquery'

describe('SyllabusBehaviors', () => {
  let container
  let consoleWarn

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    editorUtils.resetRCE()
    jest.spyOn(Sidebar, 'init')
    consoleWarn = jest.spyOn(console, 'warn').mockImplementation(() => {})
  })

  afterEach(() => {
    document.body.removeChild(container)
    if (document.querySelector('.ui-dialog')) {
      document.removeEventListener('keyup.tinymce_keyboard_shortcuts')
      document.removeEventListener('editorKeyUp')
      document.querySelector('.ui-dialog').remove()
    }
    editorUtils.resetRCE()
    jest.clearAllMocks()
    consoleWarn.mockRestore()
  })

  describe('bindToEditSyllabus', () => {
    it('sets focus to the edit button when hide_edit occurs', () => {
      const editLink = document.createElement('a')
      editLink.href = '#'
      editLink.className = 'edit_syllabus_link'
      editLink.textContent = 'Edit Link'
      container.appendChild(editLink)

      const form = document.createElement('form')
      form.id = 'edit_course_syllabus_form'
      container.appendChild(form)

      SyllabusBehaviors.bindToEditSyllabus()
      editLink.focus()
      form.dispatchEvent(new Event('hide_edit'))

      expect(document.activeElement).toBe(editLink)
      expect(editLink.getAttribute('aria-expanded')).toBe('false')
    })

    it('skips initializing sidebar when edit link is absent', () => {
      SyllabusBehaviors.bindToEditSyllabus()
      expect(Sidebar.init).not.toHaveBeenCalled()
    })

    it('sets syllabus_body data value when showing edit form', () => {
      const fresh = {val: jest.fn()}
      jest.spyOn(RichContentEditor, 'freshNode').mockReturnValue(fresh)
      jest.spyOn(RichContentEditor, 'loadNewEditor').mockImplementation()

      const syllabus = document.createElement('div')
      syllabus.id = 'course_syllabus'
      container.appendChild(syllabus)

      const editLink = document.createElement('a')
      editLink.href = '#'
      editLink.className = 'edit_syllabus_link'
      editLink.textContent = 'Edit Link'
      container.appendChild(editLink)

      const form = document.createElement('form')
      form.id = 'edit_course_syllabus_form'
      container.appendChild(form)

      const textarea = document.createElement('textarea')
      textarea.id = 'course_syllabus_body'
      container.appendChild(textarea)

      const text = 'foo'
      $(syllabus).data('syllabus_body', text)

      const $form = SyllabusBehaviors.bindToEditSyllabus()
      $form.trigger('edit')

      expect(editLink.getAttribute('aria-expanded')).toBe('true')
      expect(RichContentEditor.freshNode).toHaveBeenCalled()
      expect(fresh.val).toHaveBeenCalledWith(text)
    })

    it('shows student view button after done editing', () => {
      const editLink = document.createElement('a')
      editLink.href = '#'
      editLink.className = 'edit_syllabus_link'
      editLink.textContent = 'Edit Link'
      container.appendChild(editLink)

      const form = document.createElement('form')
      form.id = 'edit_course_syllabus_form'
      container.appendChild(form)

      const studentView = document.createElement('a')
      studentView.href = '#'
      studentView.id = 'easy_student_view'
      studentView.style.display = 'none'
      container.appendChild(studentView)

      SyllabusBehaviors.bindToEditSyllabus()
      form.dispatchEvent(new Event('hide_edit'))

      expect(studentView.style.display).toBe('')
    })
  })

  describe('bindToMiniCalendar', () => {
    it('selects first event when clicking "Jump to Today" with no dates', () => {
      const eventRow = document.createElement('tr')
      eventRow.id = 'testTr'
      eventRow.className = 'date detail_list syllabus_assignment related-assignment_4'
      eventRow.dataset.workflowState = 'published'
      container.appendChild(eventRow)

      const jumpLink = document.createElement('a')
      jumpLink.id = 'testLink'
      jumpLink.href = '#'
      jumpLink.className = 'jump_to_today_link'
      jumpLink.textContent = 'Jump to Today'
      container.appendChild(jumpLink)

      SyllabusBehaviors.bindToMiniCalendar()
      expect(eventRow.classList.contains('selected')).toBe(false)

      jumpLink.click()
      expect(eventRow.classList.contains('selected')).toBe(true)
    })

    it('selects first future event when clicking "Jump to Today"', () => {
      const event1 = document.createElement('tr')
      event1.id = 'test4'
      event1.className =
        'date detail_list events_4000_07_28 syllabus_assignment related-assignment_4'
      event1.dataset.workflowState = 'published'
      event1.innerHTML =
        '<td scope="row" rowspan="1" valign="top" class="day_date" data-date="4000_07_28">Thu Jul 28, 4000</td>'
      container.appendChild(event1)

      const event2 = document.createElement('tr')
      event2.id = 'test9'
      event2.className =
        'date detail_list events_4000_09_09 syllabus_assignment related-assignment_9'
      event2.dataset.workflowState = 'published'
      event2.innerHTML =
        '<td scope="row" rowspan="1" valign="top" class="day_date" data-date="4000_09_09">Fri Sep 9, 4000</td>'
      container.appendChild(event2)

      const jumpLink = document.createElement('a')
      jumpLink.id = 'testLink'
      jumpLink.href = '#'
      jumpLink.className = 'jump_to_today_link'
      jumpLink.textContent = 'Jump to Today'
      container.appendChild(jumpLink)

      SyllabusBehaviors.bindToMiniCalendar()
      expect(event1.classList.contains('selected')).toBe(false)
      expect(event2.classList.contains('selected')).toBe(false)

      jumpLink.click()
      expect(event1.classList.contains('selected')).toBe(true)
      expect(event2.classList.contains('selected')).toBe(false)
    })

    it('selects most recent past event when clicking "Jump to Today" with mixed dates', () => {
      const events = [
        {
          id: 'test0',
          date: '',
          className: 'date detail_list syllabus_assignment related-assignment_4',
        },
        {
          id: 'test1',
          date: '2000_07_28',
          className: 'date detail_list events_2000_07_28 syllabus_assignment related-assignment_4',
        },
        {
          id: 'test2',
          date: '2000_09_09',
          className: 'date detail_list events_2000_09_09 syllabus_assignment related-assignment_9',
        },
        {
          id: 'test3',
          date: '4000_07_28',
          className: 'date detail_list events_4000_07_28 syllabus_assignment related-assignment_4',
        },
        {
          id: 'test4',
          date: '4000_09_09',
          className: 'date detail_list events_4000_09_09 syllabus_assignment related-assignment_9',
        },
      ]

      events.forEach(event => {
        const tr = document.createElement('tr')
        tr.id = event.id
        tr.className = event.className
        tr.dataset.workflowState = 'published'
        if (event.date) {
          tr.innerHTML = `<td scope="row" rowspan="1" valign="top" class="day_date" data-date="${event.date}">Date</td>`
        }
        container.appendChild(tr)
      })

      const jumpLink = document.createElement('a')
      jumpLink.id = 'testLink'
      jumpLink.href = '#'
      jumpLink.className = 'jump_to_today_link'
      jumpLink.textContent = 'Jump to Today'
      container.appendChild(jumpLink)

      SyllabusBehaviors.bindToMiniCalendar()
      events.forEach(event => {
        expect(document.getElementById(event.id).classList.contains('selected')).toBe(false)
      })

      jumpLink.click()
      expect(document.getElementById('test2').classList.contains('selected')).toBe(true)
      events
        .filter(e => e.id !== 'test2')
        .forEach(event => {
          expect(document.getElementById(event.id).classList.contains('selected')).toBe(false)
        })
    })
  })
})
