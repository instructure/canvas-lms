/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import CourseSelect, {ALL_COURSES_ID} from '../CourseSelect'

const createProps = overrides => {
  return {
    mainPage: true,
    options: {
      allCourses: [{_id: ALL_COURSES_ID, contextName: 'All Courses', assetString: 'all_courses'}],
      favoriteCourses: [
        {_id: '1', contextName: 'Charms', assetString: 'course_1'},
        {_id: '2', contextName: 'Transfiguration', assetString: 'course_2'},
      ],
      moreCourses: [
        {_id: '3', contextName: 'Potions', assetString: 'course_3'},
        {_id: '4', contextName: 'History of Magic', assetString: 'course_4'},
        {_id: '5', contextName: 'Herbology', assetString: 'course_5'},
        {_id: '6', contextName: 'Defense Against the Dark Arts', assetString: 'course_6'},
      ],
      concludedCourses: [
        {_id: '7', contextName: 'Muggle Studies', assetString: 'course_7'},
        {_id: '8', contextName: 'Astronomy', assetString: 'course_8'},
      ],
      groups: [
        {_id: '1', contextName: 'Gryffindor Bros', assetString: 'group_1'},
        {_id: '2', contextName: 'Quidditch', assetString: 'group_2'},
        {_id: '3', contextName: "Dumbledore's Army", assetString: 'group_3'},
      ],
    },
    onCourseFilterSelect: () => {},
    ...overrides,
  }
}

beforeEach(() => {
  const liveRegion = document.createElement('DIV')
  liveRegion.setAttribute('id', 'screenreader_alert_holder')
  liveRegion.setAttribute('role', 'alert')
  document.body.appendChild(liveRegion)
})

describe('CourseSelect', () => {
  it('renders the course select', () => {
    const props = createProps()
    const {getByTestId} = render(
      <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
        <CourseSelect {...props} />
      </AlertManagerContext.Provider>
    )
    expect(getByTestId('course-select')).toBeInTheDocument()
  })

  it('opens the select and allows selecting an option', () => {
    const props = createProps()
    const mockCourseFilterSet = jest.fn()
    props.onCourseFilterSelect = mockCourseFilterSet
    const {getByTestId, getByText} = render(
      <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
        <CourseSelect {...props} />
      </AlertManagerContext.Provider>
    )
    const select = getByTestId('course-select')
    fireEvent.click(select)
    fireEvent.click(getByText('Potions'))
    expect(mockCourseFilterSet.mock.calls[0][0].contextID).toBe('course_3')
  })

  it('filters the options when typing', () => {
    const props = createProps()
    const {getByTestId, queryByText} = render(
      <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
        <CourseSelect {...props} />
      </AlertManagerContext.Provider>
    )
    const select = getByTestId('course-select')
    fireEvent.click(select)
    fireEvent.change(select, {target: {value: 'Gryff'}})
    expect(queryByText('Potions')).toBe(null)
    expect(queryByText('Gryffindor Bros')).toBeInTheDocument()
  })

  describe('all_courses option', () => {
    it('is present regardless of the current filter', () => {
      const props = createProps()
      const {getByTestId, queryByText} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <CourseSelect {...props} />
        </AlertManagerContext.Provider>
      )
      const select = getByTestId('course-select')
      fireEvent.click(select)
      fireEvent.change(select, {target: {value: 'Gryff'}})
      expect(queryByText('All Courses')).toBeInTheDocument()
    })

    it('resets mailbox selections when selected', () => {
      const filterMock = jest.fn()
      const props = createProps({
        onCourseFilterSelect: filterMock,
      })
      const {getByTestId, getByText} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <CourseSelect {...props} />
        </AlertManagerContext.Provider>
      )
      const select = getByTestId('course-select')
      fireEvent.click(select)
      fireEvent.click(getByText('All Courses'))
      expect(select.value).toBe('')
      // assert filter id is updated to null for network request
      expect(filterMock.mock.calls.length).toBe(1)
      expect(filterMock.mock.calls[0][0].contextID).toBe(null)
    })
  })
})
