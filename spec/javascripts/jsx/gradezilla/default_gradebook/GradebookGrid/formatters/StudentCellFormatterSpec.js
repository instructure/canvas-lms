/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {createGradebook, setFixtureHtml} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'
import StudentCellFormatter from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/StudentCellFormatter'

QUnit.module('GradebookGrid StudentCellFormatter', hooks => {
  let $fixture
  let gradebook
  let formatter
  let student

  hooks.beforeEach(() => {
    $fixture = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($fixture)

    gradebook = createGradebook({})
    sinon.stub(gradebook, 'saveSettings')
    formatter = new StudentCellFormatter(gradebook)

    gradebook.setSections([
      {id: '2001', name: 'Freshmen'},
      {id: '2002', name: 'Sophomores'},
      {id: '2003', name: 'Juniors'},
      {id: '2004', name: 'Seniors'}
    ])

    student = {
      enrollments: [{grades: {html_url: 'http://example.com/grades/1101'}}],
      id: '1101',
      isConcluded: false,
      isInactive: false,
      login_id: 'adam.jones@example.com',
      name: 'Adam Jones',
      sections: ['2001', '2003', '2004'],
      sis_user_id: 'sis_student_1101',
      integration_id: 'integration_id_1101',
      sortable_name: 'Jones, Adam'
    }
  })

  hooks.afterEach(() => {
    $fixture.remove()
  })

  function renderCell() {
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      null, // value
      null, // column definition
      student // dataContext
    )
    return $fixture
  }

  function studentGradesLink() {
    return renderCell().querySelector('.student-grades-link')
  }

  QUnit.module('when the student is a placeholder', () => {
    test('renders no content when the student is a placeholder', () => {
      student = {isPlaceholder: true}
      strictEqual(renderCell().innerHTML, '')
    })
  })

  QUnit.module('#render() with an active student', () => {
    test('includes a link to the student grades', () => {
      const expectedUrl = 'http://example.com/grades/1101#tab-assignments'
      equal(studentGradesLink().href, expectedUrl)
    })

    test('renders the student name when displaying names as "first, last"', () => {
      equal(studentGradesLink().innerHTML, student.name)
    })

    test('does not escape html in the student name when displaying names as "first, last"', () => {
      // student names have already been escaped
      student.name = '&lt;span&gt;Adam Jones&lt;/span&gt;'
      equal(studentGradesLink().innerHTML, '&lt;span&gt;Adam Jones&lt;/span&gt;')
    })

    test('renders the sortable name when displaying names as "last, first"', () => {
      gradebook.setSelectedPrimaryInfo('last_first', true) // skipRedraw
      equal(studentGradesLink().innerHTML, 'Jones, Adam')
    })

    test('does not escape html in the student name when displaying names as "last, first"', () => {
      // student names have already been escaped
      gradebook.setSelectedPrimaryInfo('last_first', true) // skipRedraw
      student.sortable_name = '&lt;span&gt;Jones, Adam&lt;/span&gt;'
      equal(studentGradesLink().innerHTML, '&lt;span&gt;Jones, Adam&lt;/span&gt;')
    })

    test('does not render an enrollment status label', () => {
      strictEqual(renderCell().querySelector('.label'), null)
    })

    test('renders section names when secondary info is "section"', () => {
      gradebook.setSelectedSecondaryInfo('section', true) // skipRedraw
      equal(
        renderCell().querySelector('.secondary-info').innerText,
        'Freshmen, Juniors, and Seniors'
      )
    })

    test('does not escape html in the section names', () => {
      //  section names have already been escaped
      gradebook.sections[2001].name = '&lt;span&gt;Freshmen&lt;/span&gt;'
      gradebook.setSelectedSecondaryInfo('section', true) // skipRedraw
      equal(
        renderCell().querySelector('.secondary-info').innerHTML,
        '&lt;span&gt;Freshmen&lt;/span&gt;, Juniors, and Seniors'
      )
    })

    test('does not render section names when sections should not be visible', () => {
      gradebook.setSections([])
      gradebook.setSelectedSecondaryInfo('section', true) // skipRedraw
      strictEqual(renderCell().querySelector('.secondary-info'), null)
    })

    test('renders the student login id when secondary info is "login_in"', () => {
      gradebook.setSelectedSecondaryInfo('login_id', true) // skipRedraw
      equal(renderCell().querySelector('.secondary-info').innerText, student.login_id)
    })

    test('renders the student SIS user id when secondary info is "sis_id"', () => {
      gradebook.setSelectedSecondaryInfo('sis_id', true) // skipRedraw
      equal(renderCell().querySelector('.secondary-info').innerText, student.sis_user_id)
    })

    test('renders the Integration ID when secondary info is "integration_id"', () => {
      gradebook.setSelectedSecondaryInfo('integration_id', true) // skipRedraw
      equal(renderCell().querySelector('.secondary-info').innerText, student.integration_id)
    })

    test('does not render secondary info when any secondary info is null and secondary info is not "none"', () => {
      student.login_id = null
      gradebook.setSelectedSecondaryInfo('login_id', true) // skipRedraw
      equal(renderCell().querySelector('.secondary-info'), null)
    })

    test('does not render secondary info when secondary info is "none"', () => {
      gradebook.setSelectedSecondaryInfo('none', true) // skipRedraw
      strictEqual(renderCell().querySelector('.secondary-info'), null)
    })

    test('student grades link doubles as a context card trigger', () => {
      strictEqual(studentGradesLink().classList.contains('student_context_card_trigger'), true)
    })

    test('student grades link includes the student id as a data attribute', () => {
      strictEqual(studentGradesLink().getAttribute('data-student_id'), student.id)
    })

    test('student grades link includes the course id as a data attribute', () => {
      strictEqual(studentGradesLink().getAttribute('data-course_id'), gradebook.options.context_id)
    })
  })

  QUnit.module('when the student is inactive', () => {
    test('renders the "inactive" status label', () => {
      student.isInactive = true
      equal(renderCell().querySelector('.label').innerText, 'inactive')
    })
  })

  QUnit.module('when the student is concluded', () => {
    test('renders the "concluded" status label', () => {
      student.isConcluded = true
      equal(renderCell().querySelector('.label').innerText, 'concluded')
    })
  })
})
