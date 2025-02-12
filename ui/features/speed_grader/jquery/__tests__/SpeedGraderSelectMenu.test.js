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
import SpeedGraderHelpers from '../speed_grader_helpers'
import SpeedGraderSelectMenu, {
  replaceDropdownIcon,
  focusHandlerAccessibilityFixes,
  selectMenuAccessibilityFixes,
} from '../speed_grader_select_menu'

describe('SpeedGraderSelectMenu', () => {
  beforeEach(() => {
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  describe('#updateSelectMenuStatus', () => {
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

    let testArea
    let selectMenu
    let fixtureNode

    beforeEach(() => {
      fixtureNode = document.createElement('div')
      fixtureNode.id = 'fixtures'
      document.body.appendChild(fixtureNode)
      testArea = document.createElement('div')
      testArea.id = 'test_area'
      fixtureNode.appendChild(testArea)

      // Add label element
      const label = document.createElement('label')
      label.setAttribute('for', 'students_selectmenu')
      label.textContent = 'Select a student'
      testArea.appendChild(label)

      selectMenu = new SpeedGraderSelectMenu(menuOptions)
      selectMenu.appendTo(testArea)

      // Wait for jQuery UI to initialize
      jest.advanceTimersByTime(0)
    })

    afterEach(() => {
      fixtureNode.remove()
      $('.ui-selectmenu-menu').remove()
    })

    describe('without sections', () => {
      it('ignores null students', () => {
        selectMenu.updateSelectMenuStatus({student: null, anonymizableId: 'id'})
        expect(true).toBeTruthy() // does not error
      })

      it('updates status for current student', () => {
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
        expect(status.hasClass('graded')).toBe(false)

        isCurrentStudent = true
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent,
          newStudentInfo,
          anonymizableId: 'id',
        })
        expect(status.hasClass('graded')).toBe(true)
      })

      it('updates to graded', () => {
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
        expect(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon i.icon-check'),
        ).toHaveLength(1)
        expect(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")'),
        ).toHaveLength(1)

        const option = $(selectMenu.option_tag_array[0])
        expect(option.hasClass('not_graded')).toBe(false)
        expect(option.text()).toBe('Guy B. Studying – graded')
        expect(option.hasClass('graded')).toBe(true)
      })

      it('updates to not_graded', () => {
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
        expect(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")'),
        ).toHaveLength(1)
        expect(entry.find('span.ui-selectmenu-item-header:contains("Sil E. Bus")')).toHaveLength(1)

        const option = $(selectMenu.option_tag_array[1])
        expect(option.hasClass('graded')).toBe(false)
        expect(option.text()).toBe('Sil E. Bus – not graded')
        expect(option.hasClass('not_graded')).toBe(true)
      })

      // We really never go to not_submitted, but a background update
      // *could* potentially do this, so we should handle it.
      it('updates to not_submitted', () => {
        const student = students[0]
        student.submission_state = 'not_submitted'
        selectMenu.updateSelectMenuStatus({
          student,
          isCurrentStudent: false,
          newStudentInfo: 'Guy B. Studying – not submitted',
          anonymizableId: 'id',
        })

        const entry = selectMenu.data('ui-selectmenu').list.find('li:eq(0)').children()
        expect(entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon')).toHaveLength(
          1,
        )
        expect(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")'),
        ).toHaveLength(1)

        const option = $(selectMenu.option_tag_array[0])
        expect(option.hasClass('graded')).toBe(false)
        expect(option.text()).toBe('Guy B. Studying – not submitted')
        expect(option.hasClass('not_submitted')).toBe(true)
      })

      // We really never go to resubmitted, but a background update *could*
      // potentially do this, so we should handle it.
      it('updates to resubmitted', () => {
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
        expect(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon:contains("●")'),
        ).toHaveLength(1)
        expect(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")'),
        ).toHaveLength(1)

        const option = $(selectMenu.option_tag_array[1])
        expect(option.hasClass('not_graded')).toBe(false)
        expect(option.text()).toBe('Sil E. Bus – graded, then resubmitted (Jul 10 at 5pm)')
        expect(option.hasClass('resubmitted')).toBe(true)
      })

      // We really never go to not_gradable, but a background update *could*
      // potentially do this, so we should handle it.
      it('updates to not_gradable', () => {
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
        expect(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon > i.icon-check'),
        ).toHaveLength(1)
        expect(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")'),
        ).toHaveLength(1)

        const option = $(selectMenu.option_tag_array[1])
        expect(option.hasClass('not_graded')).toBe(false)
        expect(option.text().trim()).toBe('Sil E. Bus – graded')
        expect(option.hasClass('graded')).toBe(true)
      })
    })

    describe('with sections', () => {
      let sections
      beforeEach(() => {
        sections = {
          name: 'Showing: Some stuff',
          options: [
            {
              id: 'section_0',
              data: {'section-id': 0},
              name: 'Show all sections',
              className: {raw: 'section_0'},
              anonymizableId: 'id',
            },
            {
              id: 'section_123',
              data: {'section-id': 123},
              name: 'Not everybody',
              className: {raw: 'section_123'},
              anonymizableId: 'id',
            },
          ],
          anonymizableId: 'id',
        }
        menuOptions.unshift(sections)
      })

      it('updates the right student in the presence of sections', () => {
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
        expect(
          entry.find('span.ui-selectmenu-item-icon.speedgrader-selectmenu-icon i.icon-check'),
        ).toHaveLength(1)
        expect(
          entry.find('span.ui-selectmenu-item-header:contains("Guy B. Studying")'),
        ).toHaveLength(1)

        const option = $(selectMenu.option_tag_array[0])
        expect(option.hasClass('not_graded')).toBe(false)
        expect(option.text()).toBe('Guy B. Studying – graded')
        expect(option.hasClass('graded')).toBe(true)
      })
    })
  })
})

describe('SpeedGraderSelectMenu (2)', () => {
  let fixtureNode
  let testArea
  let selectMenu

  beforeEach(() => {
    jest.useFakeTimers()
    fixtureNode = document.createElement('div')
    fixtureNode.id = 'fixtures'
    document.body.appendChild(fixtureNode)
    testArea = document.createElement('div')
    testArea.id = 'test_area'
    fixtureNode.appendChild(testArea)

    // Add label element before selectMenu initialization
    const label = document.createElement('label')
    label.setAttribute('for', 'students_selectmenu')
    label.textContent = 'Select a student'
    testArea.appendChild(label)

    selectMenu = new SpeedGraderSelectMenu([])

    // Wait for jQuery UI to initialize
    jest.advanceTimersByTime(0)
  })

  afterEach(() => {
    jest.useRealTimers()
    fixtureNode.remove()
    $('.ui-selectmenu-menu').remove()
  })

  it('Properly changes the a and select tags', () => {
    testArea.innerHTML =
      '<select id="students_selectmenu" style="foo" aria-disabled="true"></select><a class="ui-selectmenu" role="presentation" aria-haspopup="true" aria-owns="true"></a>'
    selectMenuAccessibilityFixes(testArea)
    expect(testArea.innerHTML).toBe(
      '<select id="students_selectmenu" class="screenreader-only" tabindex="0"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"></a>',
    )
  })

  it('The span tag decorates properly with focus event', () => {
    testArea.innerHTML =
      '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
    focusHandlerAccessibilityFixes(testArea)
    const event = new Event('focus')
    document.getElementById('hit_me').dispatchEvent(event)
    expect(testArea.innerHTML).toBe(
      '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>',
    )
  })

  it('The span tag decorates properly with focusout event', () => {
    testArea.innerHTML =
      '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
    focusHandlerAccessibilityFixes(testArea)
    const event = new Event('blur')
    document.getElementById('hit_me').dispatchEvent(event)
    expect(testArea.innerHTML).toBe(
      '<a id="hit_me" class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>',
    )
  })

  it('The span tag decorates properly with select tag focus event', () => {
    testArea.innerHTML =
      '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
    focusHandlerAccessibilityFixes(testArea)
    const event = new Event('focus')
    document.getElementById('students_selectmenu').dispatchEvent(event)
    expect(testArea.innerHTML).toBe(
      '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>',
    )
  })

  it('The span tag decorates properly with select tag focusout event', () => {
    testArea.innerHTML =
      '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>'
    focusHandlerAccessibilityFixes(testArea)
    const event = new Event('blur')
    document.getElementById('students_selectmenu').dispatchEvent(event)
    expect(testArea.innerHTML).toBe(
      '<select id="students_selectmenu" class="screenreader-only"></select><a class="ui-selectmenu" aria-hidden="true" tabindex="-1" style="margin: 0px;"><span class="ui-selectmenu-icon" style="background-position: 0px 0px;"></span></a>',
    )
  })

  it('A key press event on the select menu causes the change function to call', () => {
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
    const selectMenuInstance = new SpeedGraderSelectMenu(optionsArray)
    selectMenuInstance.appendTo('#test_area', () => (fired = true))
    const event = new Event('keyup')
    event.keyCode = 37
    document.getElementById('students_selectmenu').dispatchEvent(event)
    expect(fired).toBe(true)
  })

  it('Properly replaces the default ui selectmenu icon with the min-arrow-down icon', () => {
    testArea.innerHTML = '<span class="ui-selectmenu-icon ui-icon"></span>'
    replaceDropdownIcon(testArea)
    expect(testArea.innerHTML).toBe(
      '<span class="ui-selectmenu-icon"><i class="icon-mini-arrow-down"></i></span>',
    )
  })

  describe('SpeedGraderSelectMenu - rendered select control', () => {
    let optionsArray

    beforeEach(() => {
      fixtureNode = document.getElementById('fixtures')
      testArea = document.createElement('div')
      testArea.id = 'test_area'
      fixtureNode.appendChild(testArea)
      optionsArray = [
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
      selectMenu = new SpeedGraderSelectMenu(optionsArray)
      selectMenu.appendTo('#test_area')

      // Wait for jQuery UI to initialize
      jest.advanceTimersByTime(0)
    })

    afterEach(() => {
      fixtureNode.remove()
      $('.ui-selectmenu-menu').remove()
    })

    it('renders a select control', () => {
      expect(selectMenu.$el.prop('tagName')).toBe('SELECT')
    })

    it.skip('renders a label for the select element', () => {
      const label = testArea.querySelector('label[for="students_selectmenu"]')
      expect(label.textContent).toBe('Select a student')
    })

    it('renders the select control with an id of students_selectmenu', () => {
      expect(selectMenu.$el.prop('id')).toBe('students_selectmenu')
    })

    it('renders one optgroup inside the select control to allow changing sections', () => {
      expect(selectMenu.$el.find('optgroup[label="Showing all sections"]')).toHaveLength(1)
    })

    it('renders two options inside the section optgroup - one for all sections and one for the specific section', () => {
      expect(selectMenu.$el.find('optgroup[label="Showing all sections"] option')).toHaveLength(2)
    })

    it('renders an option for showing all sections', () => {
      const optgroup = selectMenu.$el.find('optgroup[label="Showing all sections"]')
      expect(optgroup.find('option:contains("Show all sections")')).toHaveLength(1)
    })

    it('renders an option for switching to section 1', () => {
      const optgroup = selectMenu.$el.find('optgroup[label="Showing all sections"]')
      expect(optgroup.find('option:contains("Change section to Section 1")')).toHaveLength(1)
    })

    it('renders two options outside the section optgroup - one for each student', () => {
      expect(selectMenu.$el.find('> option')).toHaveLength(2)
    })

    it('renders an option for Student 1', () => {
      expect(
        selectMenu.$el.find(
          '> option[value="1"]:contains("Student 1"):contains("not graded").not_graded.ui-selectmenu-hasIcon',
        ),
      ).toHaveLength(1)
    })

    it('renders an option for Student 2', () => {
      expect(
        selectMenu.$el.find(
          '> option[value="3"]:contains("Student 2"):contains("graded").graded.ui-selectmenu-hasIcon',
        ),
      ).toHaveLength(1)
    })

    it('option for Student 2 comes first as in the order of the options passed in', () => {
      const options = selectMenu.$el.find('> option.ui-selectmenu-hasIcon').toArray()
      const optionValues = options.map(opt => $(opt).attr('value'))
      expect(optionValues).toEqual(['3', '1'])
    })
  })
})

describe('SpeedGraderSelectMenu - rendered select control (2)', () => {
  let fixtureNode
  let testArea
  let selectMenu
  let optionsArray

  beforeEach(() => {
    jest.useFakeTimers()
    fixtureNode = document.createElement('div')
    fixtureNode.id = 'fixtures'
    document.body.appendChild(fixtureNode)
    testArea = document.createElement('div')
    testArea.id = 'test_area'
    fixtureNode.appendChild(testArea)
    optionsArray = [
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
    selectMenu = new SpeedGraderSelectMenu(optionsArray)
    selectMenu.appendTo('#test_area')

    // Wait for jQuery UI to initialize
    jest.advanceTimersByTime(0)
  })

  afterEach(() => {
    jest.useRealTimers()
    fixtureNode.remove()
    $('.ui-selectmenu-menu').remove()
  })

  it('renders a select control', () => {
    expect(selectMenu.$el.prop('tagName')).toBe('SELECT')
  })

  it('renders a label for the select element', () => {
    const label = testArea.querySelector('label[for="students_selectmenu"]')
    expect(label.textContent).toBe('Select a student')
  })

  it('renders the select control with an id of students_selectmenu', () => {
    expect(selectMenu.$el.prop('id')).toBe('students_selectmenu')
  })

  it('renders one optgroup inside the select control to allow changing sections', () => {
    expect(selectMenu.$el.find('optgroup[label="Showing all sections"]')).toHaveLength(1)
  })

  it('renders two options inside the section optgroup - one for all sections and one for the specific section', () => {
    expect(selectMenu.$el.find('optgroup[label="Showing all sections"] option')).toHaveLength(2)
  })

  it('renders an option for showing all sections', () => {
    const optgroup = selectMenu.$el.find('optgroup[label="Showing all sections"]')
    expect(optgroup.find('option:contains("Show all sections")')).toHaveLength(1)
  })

  it('renders an option for switching to section 1', () => {
    const optgroup = selectMenu.$el.find('optgroup[label="Showing all sections"]')
    expect(optgroup.find('option:contains("Change section to Section 1")')).toHaveLength(1)
  })

  it('renders two options outside the section optgroup - one for each student', () => {
    expect(selectMenu.$el.find('> option')).toHaveLength(2)
  })

  it('renders an option for Student 1', () => {
    expect(
      selectMenu.$el.find(
        '> option[value="1"]:contains("Student 1"):contains("not graded").not_graded.ui-selectmenu-hasIcon',
      ),
    ).toHaveLength(1)
  })

  it('renders an option for Student 2', () => {
    expect(
      selectMenu.$el.find(
        '> option[value="3"]:contains("Student 2"):contains("graded").graded.ui-selectmenu-hasIcon',
      ),
    ).toHaveLength(1)
  })

  it('option for Student 2 comes first as in the order of the options passed in', () => {
    const options = selectMenu.$el.find('> option.ui-selectmenu-hasIcon').toArray()
    const optionValues = options.map(opt => $(opt).attr('value'))
    expect(optionValues).toEqual(['3', '1'])
  })
})
