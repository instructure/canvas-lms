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

import Grid from 'jsx/assignments/GradeSummary/components/GradesGrid/Grid'
import GradesGrid from 'jsx/assignments/GradeSummary/components/GradesGrid'

QUnit.module('GradeSummary GradesGrid', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      disabledCustomGrade: false,
      finalGrader: {
        graderId: 'teach',
        id: '1105'
      },
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ],
      grades: {
        1111: {
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
        1112: {
          1102: {
            grade: 'C',
            graderId: '1102',
            id: '4603',
            score: 7.8,
            selected: false,
            studentId: '1112'
          }
        },
        1113: {
          1101: {
            grade: 'A',
            graderId: '1101',
            id: '4604',
            score: 10,
            selected: false,
            studentId: '1113'
          }
        }
      },
      onGradeSelect() {},
      selectProvisionalGradeStatuses: {},
      students: [
        {id: '1111', displayName: 'Adam Jones'},
        {id: '1112', displayName: 'Betty Ford'},
        {id: '1113', displayName: 'Charlie Xi'},
        {id: '1114', displayName: 'Dana Smith'}
      ]
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    wrapper = mount(<GradesGrid {...props} />)
  }

  function getGraderNames() {
    const headers = wrapper.find('th.GradesGrid__GraderHeader')
    return headers.map(header => header.text())
  }

  function getStudentNames() {
    const headers = wrapper.find('th.GradesGrid__BodyRowHeader')
    return headers.map(header => header.text())
  }

  function goToPage(page) {
    const onPageClick = wrapper.find('PageNavigation').prop('onPageClick')
    onPageClick(page)
  }

  test('displays the grader names in the column headers', () => {
    mountComponent()
    deepEqual(getGraderNames(), ['Miss Frizzle', 'Mr. Keating'])
  })

  test('includes a row for each student', () => {
    mountComponent()
    strictEqual(wrapper.find('tr.GradesGrid__BodyRow').length, 4)
  })

  test('sends disabledCustomGrade to the Grid', () => {
    mountComponent()
    const grid = wrapper.find(Grid)
    strictEqual(grid.prop('disabledCustomGrade'), false)
  })

  test('sends finalGrader to the Grid', () => {
    mountComponent()
    const grid = wrapper.find(Grid)
    strictEqual(grid.prop('finalGrader'), props.finalGrader)
  })

  test('sends graders to the Grid', () => {
    mountComponent()
    const grid = wrapper.find(Grid)
    strictEqual(grid.prop('graders'), props.graders)
  })

  test('sends onGradeSelect to the Grid', () => {
    mountComponent()
    const grid = wrapper.find(Grid)
    strictEqual(grid.prop('onGradeSelect'), props.onGradeSelect)
  })

  test('sends selectProvisionalGradeStatuses to the Grid', () => {
    mountComponent()
    const grid = wrapper.find(Grid)
    strictEqual(grid.prop('selectProvisionalGradeStatuses'), props.selectProvisionalGradeStatuses)
  })

  test('adds rows as students are added', () => {
    const {students} = props
    props.students = students.slice(0, 2)
    mountComponent()
    wrapper.setProps({students})
    strictEqual(wrapper.find('tr.GradesGrid__BodyRow').length, 4)
  })

  test('displays the student names in the row headers', () => {
    mountComponent()
    deepEqual(getStudentNames(), ['Adam Jones', 'Betty Ford', 'Charlie Xi', 'Dana Smith'])
  })

  test('enumerates students for names when students are anonymous', () => {
    for (let i = 0; i < props.students.length; i++) {
      props.students[i].displayName = null
    }
    mountComponent()
    deepEqual(getStudentNames(), ['Student 1', 'Student 2', 'Student 3', 'Student 4'])
  })

  test('enumerates additional students for names as they are added', () => {
    for (let i = 0; i < props.students.length; i++) {
      props.students[i].displayName = null
    }
    const {students} = props
    props.students = students.slice(0, 2)
    mountComponent()
    wrapper.setProps({students})
    deepEqual(getStudentNames(), ['Student 1', 'Student 2', 'Student 3', 'Student 4'])
  })

  test('does not display page navigation when only one page of students is loaded', () => {
    mountComponent()
    strictEqual(wrapper.find('PageNavigation').length, 0)
  })

  QUnit.module('when multiple pages of students are loaded', hooks => {
    hooks.beforeEach(() => {
      props.students = []
      for (let id = 1111; id <= 1160; id++) {
        props.students.push({id: `${id}`, displayName: `Student ${id}`})
      }
    })

    test('displays page navigation', () => {
      mountComponent()
      strictEqual(wrapper.find('PageNavigation').length, 1)
    })

    test('displays only 20 rows on a page', () => {
      mountComponent()
      strictEqual(wrapper.find('tr.GradesGrid__BodyRow').length, 20)
    })

    test('displays the first 20 students on the first page', () => {
      mountComponent()
      const expectedNames = props.students.slice(0, 20).map(student => student.displayName)
      deepEqual(getStudentNames(), expectedNames)
    })

    test('displays the next 20 students after navigating to the second page', () => {
      mountComponent()
      goToPage(2)
      const expectedNames = props.students.slice(20, 40).map(student => student.displayName)
      deepEqual(getStudentNames(), expectedNames)
    })

    test('updates the current page as students are added', () => {
      const {students} = props
      props.students = students.slice(0, 30) // page 2 has 10 students
      mountComponent()
      goToPage(2)
      wrapper.setProps({students})
      const expectedNames = students.slice(20, 40).map(student => student.displayName)
      deepEqual(getStudentNames(), expectedNames)
    })

    test('continues enumeration on students across pages', () => {
      const anonymousNames = []
      for (let i = 0; i < props.students.length; i++) {
        props.students[i].displayName = null
        anonymousNames.push(`Student ${i + 1}`)
      }
      mountComponent()
      goToPage(2)
      // Student 21, Student 22, ..., Student 40
      deepEqual(getStudentNames(), anonymousNames.slice(20, 40))
    })
  })
})
