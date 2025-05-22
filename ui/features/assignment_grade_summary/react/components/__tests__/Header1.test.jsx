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

import React from 'react'
import {render, act, screen} from '@testing-library/react'
import {Provider} from 'react-redux'

import * as AssignmentActions from '../../assignment/AssignmentActions'

import Header from '../Header'
import configureStore from '../../configureStore'

describe('GradeSummary Header', () => {
  let students
  let grades
  let store
  let storeEnv
  let wrapper

  beforeEach(() => {
    students = [
      {id: '1', displayName: 'Adam Jones'},
      {id: '2', displayName: 'Larry Brown'},
    ]
    grades = [
      {grade: '4', graderId: '1103', id: '34', score: 4, selected: true, studentId: '1'},
      {grade: '6', graderId: '1102', id: '35', score: 8, selected: false, studentId: '1'},
      {grade: '8', graderId: '1103', id: '36', score: 3, selected: true, studentId: '2'},
      {grade: '10', graderId: '1102', id: '37', score: 9, selected: false, studentId: '2'},
    ]
    window.ENV = {
      GRADERS: [
        {
          grader_name: 'Charlie Xi',
          id: '4502',
          user_id: '1103',
          grader_selectable: true,
          graderId: '4502',
        },
        {
          grader_name: 'Betty Ford',
          id: '4501',
          user_id: '1102',
          grader_selectable: false,
          graderId: '4501',
        },
      ],
    }
    storeEnv = {
      assignment: {
        courseId: '1201',
        gradesPublished: false,
        id: '2301',
        muted: true,
        title: 'Example Assignment',
      },
      currentUser: {
        graderId: 'teach',
        id: '1105',
      },
      graders: [
        {
          grader_name: 'Charlie Xi',
          id: '4502',
          user_id: '1103',
          grader_selectable: true,
          graderId: '4502',
        },
        {
          grader_name: 'Betty Ford',
          id: '4501',
          user_id: '1102',
          grader_selectable: false,
          graderId: '4501',
        },
      ],
    }
  })

  function mountComponent() {
    store = configureStore(storeEnv)
    wrapper = render(
      <Provider store={store}>
        <Header />
      </Provider>,
    )
  }

  it('includes the "Grade Summary" heading', () => {
    mountComponent()
    expect(wrapper.container.querySelector('h1').textContent).toBe('Grade Summary')
  })

  it('includes the assignment title', () => {
    mountComponent()
    const children = wrapper.container.querySelector('header').children
    const childArray = [...children].map(child => child)
    const headingIndex = childArray.findIndex(child => child.textContent === 'Grade Summary')
    expect(childArray[headingIndex + 1].textContent).toBe('Example Assignment')
  })

  it('includes a "grader with inactive enrollments" message when a grader with inactive enrollment was selected', () => {
    mountComponent()
    act(() => {
      store.dispatch(
        AssignmentActions.setReleaseGradesStatus(
          AssignmentActions.SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
        ),
      )
    })
    expect(screen.getByText('grader with inactive enrollments', {exact: false})).toBeInTheDocument()
  })

  it('includes a "grades released" message when grades have been released', () => {
    storeEnv.assignment.gradesPublished = true
    mountComponent()
    expect(screen.getByText('they have already been released', {exact: false})).toBeInTheDocument()
  })

  it('excludes the "grades released" message when grades have not yet been released', () => {
    mountComponent()
    expect(screen.queryByText('they have already been released', {exact: false})).toBeNull()
  })

  describe('Graders Table', () => {
    it('is not displayed when there are no graders', () => {
      storeEnv.graders = []
      mountComponent()
      expect(screen.queryByTestId('graders-table')).toBeNull()
    })

    it('is displayed when there are graders', () => {
      mountComponent()
      expect(screen.getByTestId('graders-table')).toBeInTheDocument()
    })
  })
})
