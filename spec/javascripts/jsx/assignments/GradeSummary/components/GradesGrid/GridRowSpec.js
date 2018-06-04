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

import React from 'react'
import {mount} from 'enzyme'

import GridRow from 'jsx/assignments/GradeSummary/components/GradesGrid/GridRow'

QUnit.module('GradeSummary GridRow', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ],
      grades: {
        1101: {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111'
        },
        1102: {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 8.9,
          selected: false,
          studentId: '1111'
        }
      },
      row: {
        studentId: '1111',
        studentName: 'Adam Jones'
      }
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    // React is unable to render partial table structures.
    wrapper = mount(
      <table>
        <tbody>
          <GridRow {...props} />
        </tbody>
      </table>
    )
  }

  test('displays the student name in the row header', () => {
    mountComponent()
    const header = wrapper.find('th.GradesGrid__BodyRowHeader')
    equal(header.text(), 'Adam Jones')
  })

  test('includes a cell for each grader', () => {
    mountComponent()
    strictEqual(wrapper.find('td.GradesGrid__ProvisionalGradeCell').length, 2)
  })

  test('displays the score of a provisional grade in the matching cell', () => {
    mountComponent()
    const cell = wrapper.find('td.grader_1102')
    equal(cell.text(), '8.9')
  })

  test('displays zero scores', () => {
    props.grades[1101].score = 0
    mountComponent()
    const cell = wrapper.find('td.grader_1101')
    equal(cell.text(), '0')
  })

  test('displays "–" (en dash) when the student grade for a given grader was cleared', () => {
    props.grades[1101].score = null
    mountComponent()
    const cell = wrapper.find('td.grader_1101')
    equal(cell.text(), '–')
  })

  test('displays "–" (en dash) when the student was not graded by a given grader', () => {
    delete props.grades[1101]
    mountComponent()
    const cell = wrapper.find('td.grader_1101')
    equal(cell.text(), '–')
  })

  test('displays "–" (en dash) when the student has no provisional grades', () => {
    delete props.grades
    mountComponent()
    const cell = wrapper.find('td.grader_1101')
    equal(cell.text(), '–')
  })
})
