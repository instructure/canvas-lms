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
import 'jquery-migrate'
import SpeedGraderHelpers from 'ui/features/speed_grader/jquery/speed_grader_helpers'
import SpeedGraderSelectMenu, {
  replaceDropdownIcon,
  focusHandlerAccessibilityFixes,
  selectMenuAccessibilityFixes,
} from 'ui/features/speed_grader/jquery/speed_grader_select_menu'

QUnit.module('SpeedGraderSelectMenu', () => {
  QUnit.module('#updateSelectMenuStatus', updateSelectMenuStatusHooks => {
    const students = [
      {
        index: 0,
        id: 4,
        name: 'Guy B. Studying',
        submission_state: 'not_graded',
        submission: {score: null, grade: null},
      },
      {
        index: 1,
        id: 12,
        name: 'Sil E. Bus',
        submission_state: 'graded',
        submission: {score: 7, grade: 70},
      },
    ]

    const menuOptions = students.map(student => {
      const className = SpeedGraderHelpers.classNameBasedOnStudent(student)
      return {id: student.id, name: student.name, className, anonymizableId: 'id'}
    })

    const fixtureNode = document.getElementById('fixtures')

    let testArea
    let selectMenu

    updateSelectMenuStatusHooks.beforeEach(() => {
      testArea = document.createElement('div')
      testArea.id = 'test_area'
      fixtureNode.appendChild(testArea)
      selectMenu = new SpeedGraderSelectMenu(menuOptions)
      selectMenu.appendTo(testArea)
    })

    updateSelectMenuStatusHooks.afterEach(() => {
      fixtureNode.innerHTML = ''
      $('.ui-selectmenu-menu').remove()
    })

    QUnit.module('without sections', () => {
      test('ignores null students', () => {
        selectMenu.updateSelectMenuStatus({student: null})
        ok(true, 'does not error')
      })

      test('updates status for current student', () => {
        const student = students[0]
        student.submission_state = 'graded'

        const status = $('.ui-selectmenu-status')

        let isCurrentStudent = false
        const newStudentInfo = 'Guy B. Studying – graded'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })
        strictEqual(status.hasClass('graded'), false)

        isCurrentStudent = true
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })
        strictEqual(status.hasClass('graded'), true)
      })

      test('updates to graded', () => {
        const student = students[0]
        student.submission_state = 'graded'
        const isCurrentStudent = false
        const newStudentInfo = 'Guy B. Studying – graded'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })

        const entry = selectMenu.data('ui-selectmenu').list.find('li:eq(0)').children()
        strictEqual(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon i.icon-check')
            .length,
          1
        )
        strictEqual(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length,
          1
        )

        const option = $(selectMenu.option_tag_array[0])
        strictEqual(option.hasClass('not_graded'), false)
        equal(option.text(), 'Guy B. Studying – graded')
        strictEqual(option.hasClass('graded'), true)
      })

      test('updates to not_graded', () => {
        const student = students[1]
        student.submission_state = 'not_graded'
        const isCurrentStudent = false
        const newStudentInfo = 'Sil E. Bus – not graded'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })

        const entry = selectMenu.data('ui-selectmenu').list.find('li:eq(1)').children()
        strictEqual(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")')
            .length,
          1
        )
        strictEqual(entry.find('span.ui-selectmenu-item-header:contains("Sil E. Bus")').length, 1)

        const option = $(selectMenu.option_tag_array[1])
        strictEqual(option.hasClass('graded'), false)
        equal(option.text(), 'Sil E. Bus – not graded')
        strictEqual(option.hasClass('not_graded'), true)
      })

      // We really never go to not_submitted, but a background update
      // *could* potentially do this, so we should handle it.
      test('updates to not_submitted', () => {
        const student = students[0]
        student.submission_state = 'not_submitted'
        selectMenu.updateSelectMenuStatus(student, false, 'Guy B. Studying – not submitted')
        const isCurrentStudent = false
        const newStudentInfo = 'Guy B. Studying – not submitted'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })

        const entry = selectMenu.data('ui-selectmenu').list.find('li:eq(0)').children()
        strictEqual(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon').length,
          1
        )
        strictEqual(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length,
          1
        )

        const option = $(selectMenu.option_tag_array[0])
        strictEqual(option.hasClass('graded'), false)
        equal(option.text(), 'Guy B. Studying – not submitted')
        strictEqual(option.hasClass('not_submitted'), true)
      })

      // We really never go to resubmitted, but a backgroud update *could*
      // potentially do this, so we should handle it.
      test('updates to resubmitted', () => {
        const student = students[1]
        student.submission_state = 'resubmitted'
        student.submission.submitted_at = '2017-07-10T17:00:00Z'
        const isCurrentStudent = false
        const newStudentInfo = 'Sil E. Bus – graded, then resubmitted (Jul 10 at 5pm)'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })

        const entry = selectMenu.data('ui-selectmenu').list.find('li:eq(0)').children()
        strictEqual(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")')
            .length,
          1
        )
        strictEqual(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length,
          1
        )

        const option = $(selectMenu.option_tag_array[1])
        strictEqual(option.hasClass('not_graded'), false)
        equal(option.text(), 'Sil E. Bus – graded, then resubmitted (Jul 10 at 5pm)')
        strictEqual(option.hasClass('resubmitted'), true)
      })

      // We really never go to not_gradable, but a backgroud update *could*
      // potentially do this, so we should handle it.
      test('updates to not_gradable', () => {
        const student = students[0]
        student.submission_state = 'not_gradeable'
        student.submission.submitted_at = '2017-07-10T17:00:00Z'
        const isCurrentStudent = false
        const newStudentInfo = 'Sil E. Bus – graded'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })

        const entry = selectMenu.data('ui-selectmenu').list.find('li:eq(0)').children()
        strictEqual(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon > i.icon-check')
            .length,
          1
        )
        strictEqual(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length,
          1
        )

        const option = $(selectMenu.option_tag_array[1])
        strictEqual(option.hasClass('not_graded'), false)
        equal(option.text().trim(), 'Sil E. Bus – graded')
        strictEqual(option.hasClass('graded'), true)
      })
    })

    QUnit.module('with sections', hooks => {
      let sections
      hooks.beforeEach(() => {
        sections = {
          name: 'Showing: Some stuff',
          options: [
            {
              id: 'section_0',
              data: {'section-id': 0},
              name: 'Show all sections',
              className: {raw: 'section_0'},
            },
            {
              id: 'section_123',
              data: {'section-id': 123},
              name: 'Not everybody',
              className: {raw: 'section_123'},
            },
          ],
        }
        menuOptions.unshift(sections)
      })

      test('updates the right student in the presence of sections', () => {
        const student = students[0]
        student.submission_state = 'graded'
        const isCurrentStudent = false
        const newStudentInfo = 'Guy B. Studying – graded'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })

        const entry = selectMenu.data('ui-selectmenu').list.find('li:eq(0)').children()
        strictEqual(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon i.icon-check')
            .length,
          1
        )
        strictEqual(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")').length,
          1
        )

        const option = $(selectMenu.option_tag_array[0])
        strictEqual(option.hasClass('not_graded'), false)
        equal(option.text(), 'Guy B. Studying – graded')
        strictEqual(option.hasClass('graded'), true)
      })
    })
  })
})

QUnit.module('SpeedGraderSelectMenu (2)', {
  setup() {
    this.fixtureNode = document.getElementById('fixtures')
    this.testArea = document.createElement('div')
    this.testArea.id = 'test_area'
    this.fixtureNode.appendChild(this.testArea)
    this.selectMenu = new SpeedGraderSelectMenu([])
  },
  teardown() {
    this.fixtureNode.innerHTML = ''
    return $('.ui-selectmenu-menu').remove()
  },
})

test('Properly changes the a and select tags', function () {
  this.testArea.innerHTML =
    '<select id="students_selectmenu" style="foo" aria-disabled="true"></select><a class="ui-selectmenu" role="presentation" aria-haspopup="true" aria-owns="true"></a>'
  selectMenuAccessibilityFixes(this.testArea)
  equal(
    this.testArea.innerHTML,
    '<select id="students_selectmenu" class="screenreader-only" tabindex="0"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"></a>'
  )
})

test('The span tag decorates properly with focus event', function () {
  this.testArea.innerHTML =
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></a>'
  focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('focus', true, true)
  document.getElementById('hit_me').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  )
})

test('The span tag decorates properly with focusout event', function () {
  this.testArea.innerHTML =
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('blur', true, true)
  document.getElementById('hit_me').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
  )
})

test('The span tag decorates properly with select tag focus event', function () {
  this.testArea.innerHTML =
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
  focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('focus', true, true)
  document.getElementById('students_selectmenu').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  )
})

test('The span tag decorates properly with select tag focusout event', function () {
  this.testArea.innerHTML =
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: -17px 0px;"></span></a>'
  focusHandlerAccessibilityFixes(this.testArea)
  const event = document.createEvent('Event')
  event.initEvent('blur', true, true)
  document.getElementById('students_selectmenu').dispatchEvent(event)
  equal(
    this.testArea.innerHTML,
    '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
  )
})

test('A key press event on the select menu causes the change function to call', () => {
  const optionsArray = [
    {
      id: '1',
      name: 'Student 1',
      className: {
        raw: 'not_graded',
        formatted: 'not graded',
      },
      anonymizableId: 'id',
    },
  ]
  let fired = false
  const selectMenu = new SpeedGraderSelectMenu(optionsArray)
  selectMenu.appendTo('#test_area', () => (fired = true))
  const event = new Event('keyup')
  event.keyCode = 37
  document.getElementById('students_selectmenu').dispatchEvent(event)
  equal(fired, true)
})

test('Properly replaces the default ui selectmenu icon with the min-arrow-down icon', function () {
  this.testArea.innerHTML = '<span class="ui-selectmenu-icon ui-icon"></span>'
  replaceDropdownIcon(this.testArea)
  equal(
    this.testArea.innerHTML,
    '<span class="ui-selectmenu-icon"><i class="icon-mini-arrow-down"></i></span>'
  )
})

QUnit.module('SpeedGraderSelectMenu - rendered select control', {
  setup() {
    this.fixtureNode = document.getElementById('fixtures')
    this.testArea = document.createElement('div')
    this.testArea.id = 'test_area'
    this.fixtureNode.appendChild(this.testArea)
    this.optionsArray = [
      {
        name: 'Showing all sections',
        options: [
          {
            id: 'section_all',
            data: {'section-id': 'all'},
            name: 'Show all sections',
            className: {raw: 'section_all'},
            anonymizableId: 'id',
          },
          {
            id: 'section_1',
            data: {'section-id': '1'},
            name: 'Change section to Section 1',
            className: {raw: 'section_1'},
            anonymizableId: 'id',
          },
        ],
        anonymizableId: 'id',
      },
      {
        id: '3',
        name: 'Student 2',
        className: {raw: 'graded', formatted: 'graded'},
        anonymizableId: 'id',
      },
      {
        id: '1',
        name: 'Student 1',
        className: {raw: 'not_graded', formatted: 'not graded'},
        anonymizableId: 'id',
      },
    ]
    this.selectMenu = new SpeedGraderSelectMenu(this.optionsArray)
    this.selectMenu.appendTo('#test_area')
  },
  teardown() {
    this.fixtureNode.innerHTML = ''
    $('.ui-selectmenu-menu').remove()
  },
})

test('renders a select control', function () {
  strictEqual(this.selectMenu.$el.prop('tagName'), 'SELECT')
})

test('renders a label for the select element', function () {
  const label = this.testArea.querySelector('label[for="students_selectmenu"]')
  strictEqual(label.textContent, 'Select a student')
})

test('renders the select control with an id of students_selectmenu', function () {
  strictEqual(this.selectMenu.$el.prop('id'), 'students_selectmenu')
})

test('renders one optgroup inside the select control to allow changing sections', function () {
  strictEqual(this.selectMenu.$el.find('optgroup[label="Showing all sections"]').length, 1)
})

test('renders two options inside the section optgroup - one for all sections and one for the specific section', function () {
  strictEqual(this.selectMenu.$el.find('optgroup[label="Showing all sections"] option').length, 2)
})

test('renders an option for showing all sections', function () {
  const optgroup = this.selectMenu.$el.find('optgroup[label="Showing all sections"]')
  strictEqual(optgroup.find('option:contains("Show all sections")').length, 1)
})

test('renders an option for switching to section 1', function () {
  const optgroup = this.selectMenu.$el.find('optgroup[label="Showing all sections"]')
  strictEqual(optgroup.find('option:contains("Change section to Section 1")').length, 1)
})

test('renders two options outside the section optgroup - one for each student', function () {
  strictEqual(this.selectMenu.$el.find('> option').length, 2)
})

test('renders an option for Student 1', function () {
  strictEqual(
    this.selectMenu.$el.find(
      '> option[value="1"]:contains("Student 1"):contains("not graded").not_graded.ui-selectmenu-hasIcon'
    ).length,
    1
  )
})

test('renders an option for Student 2', function () {
  strictEqual(
    this.selectMenu.$el.find(
      '> option[value="3"]:contains("Student 2"):contains("graded").graded.ui-selectmenu-hasIcon'
    ).length,
    1
  )
})

test('option for Student 2 comes first as in the order of the options passed in', function () {
  const options = this.selectMenu.$el.find('> option.ui-selectmenu-hasIcon').toArray()
  deepEqual(
    options.map(opt => $(opt).attr('value')),
    ['3', '1']
  )
})
