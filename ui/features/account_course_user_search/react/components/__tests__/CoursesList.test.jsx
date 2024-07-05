/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {omit} from 'lodash'
import CoursesList from '../CoursesList'

describe('Account Course User Search CoursesList Sorting', () => {
  const coursesProps = {
    courses: [
      {
        id: '1',
        name: 'A',
        sis_course_id: 'SIS 1',
        workflow_state: 'available',
        total_students: 6,
        subaccount_name: 'subaccount name',
        subaccount_id: '1',
        teachers: [
          {
            id: '1',
            display_name: 'Testing Teacher',
          },
        ],
        term: {
          name: 'A Term',
        },
      },
      {
        id: '2',
        name: 'Ba',
        sis_course_id: 'SIS Ba',
        workflow_state: 'available',
        total_students: 7,
        subaccount_name: 'subaccount name',
        subaccount_id: '2',
        teachers: [
          {
            id: '1',
            display_name: 'Testing Teacher',
          },
        ],
        term: {
          name: 'Ba Term',
        },
      },
      {
        id: '3',
        name: 'Bb',
        sis_course_id: 'SIS Bb',
        workflow_state: 'available',
        total_students: 6,
        subaccount_name: 'subaccount name',
        subaccount_id: '3',
        teachers: [
          {
            id: '1',
            display_name: 'Testing Teacher',
          },
        ],
        term: {
          name: 'Bb Term',
        },
      },
      {
        id: '4',
        name: 'C',
        sis_course_id: 'SIS C',
        workflow_state: 'available',
        total_students: 6,
        subaccount_name: 'subaccount name',
        subaccount_id: '4',
        teachers: [
          {
            id: '1',
            display_name: 'Testing Teacher',
          },
        ],
        term: {
          name: 'C Term',
        },
      },
      {
        id: '5',
        name: 'De',
        sis_course_id: 'SIS De',
        workflow_state: 'available',
        total_students: 11,
        subaccount_name: 'subaccount name',
        subaccount_id: '5',
        teachers: [
          {
            id: '1',
            display_name: 'Testing Teacher',
          },
        ],
        term: {
          name: 'De Term',
        },
      },
      {
        id: '6',
        name: 'Dz',
        sis_course_id: 'SIS Dz',
        workflow_state: 'available',
        subaccount_name: 'subaccount name',
        subaccount_id: '6',
        total_students: 10,
        teachers: [
          {
            id: '1',
            display_name: 'Testing Teacher',
          },
        ],
        term: {
          name: 'Dz Term',
        },
      },
    ],
    roles: [
      {
        id: '1',
        course_id: '1',
        roles: [
          {
            base_role_type: 'StudentEnrollment',
          },
        ],
      },
    ],
    sort: 'course_name',
    order: 'asc',
    onChangeSort: () => {},
  }

  Object.entries({
    course_status: 'Status',
    course_name: 'Course',
    sis_course_id: 'SIS ID',
    term: 'Term',
    teacher: 'Teacher',
    subaccount: 'Sub-Account',
  }).forEach(([columnID, label]) => {
    test(`sorting by ${columnID} asc puts up-arrow on ${label} only`, () => {
      const wrapper = render(
        <CoursesList
          {...{
            ...coursesProps,
            sort: columnID,
            order: 'asc',
          }}
        />
      )

      expect(wrapper.container.querySelector(`svg[name="IconMiniArrowDown"]`)).toBeNull()
      expect(wrapper.container.querySelector(`svg[name="IconMiniArrowUp"]`)).toBeInTheDocument()

      const expectedTip =
        {
          course_name: 'Click to sort by name descending',
          total_students: 'Click to sort by number of students descending',
        }[columnID] || `Click to sort by ${label} descending`

      expect(wrapper.getByText(RegExp(expectedTip, 'i'))).toBeInTheDocument()
    })

    test(`sorting by ${columnID} desc puts down-arrow on ${label} only`, () => {
      const wrapper = render(
        <CoursesList
          {...{
            ...coursesProps,
            sort: columnID,
            order: 'desc',
          }}
        />
      )

      expect(wrapper.container.querySelector(`svg[name="IconMiniArrowUp"]`)).toBeNull()
      expect(wrapper.container.querySelector(`svg[name="IconMiniArrowDown"]`)).toBeInTheDocument()

      const expectedTip =
        {
          course_name: 'Click to sort by name ascending',
          total_students: 'Click to sort by number of students ascending',
        }[columnID] || `Click to sort by ${label} ascending`

      expect(wrapper.getByText(RegExp(expectedTip, 'i'))).toBeInTheDocument()
    })

    test(`clicking the ${label} column header calls onChangeSort with ${columnID}`, () => {
      const onChangeSort = jest.fn()
      const wrapper = render(
        <CoursesList
          {...{
            ...coursesProps,
            onChangeSort,
          }}
        />
      )

      wrapper.getByRole('button', {name: label}).click()
      expect(onChangeSort).toHaveBeenCalledTimes(1)
      expect(onChangeSort).toHaveBeenCalledWith(columnID)
    })
  })

  test('displays SIS ID column if any course has one', () => {
    const wrapper = render(<CoursesList {...coursesProps} />)
    expect(wrapper.getByText('SIS ID')).toBeInTheDocument()
  })

  test(`doesn't display SIS ID column if no course has one`, () => {
    const propsWithoutSISids = {
      ...coursesProps,
      courses: coursesProps.courses.map(c => omit(c, ['sis_course_id'])),
    }
    const wrapper = render(<CoursesList {...propsWithoutSISids} />)
    expect(wrapper.queryByText('SIS ID')).not.toBeInTheDocument()
  })

  test('displays courses in the right order', () => {
    const wrapper = render(<CoursesList {...coursesProps} />)
    const nodes = wrapper.container.querySelectorAll("tbody[data-automation='courses list'] tr")

    expect(nodes).toHaveLength(6)
    expect(nodes[0]).toHaveTextContent('A Term')
    expect(nodes[1]).toHaveTextContent('Ba Term')
    expect(nodes[2]).toHaveTextContent('Bb Term')
    expect(nodes[3]).toHaveTextContent('C Term')
    expect(nodes[4]).toHaveTextContent('De Term')
    expect(nodes[5]).toHaveTextContent('Dz Term')
  })

  test('displays status column', () => {
    const wrapper = render(<CoursesList {...coursesProps} />)
    expect(wrapper.getByText('Status')).toBeInTheDocument()
  })
})
