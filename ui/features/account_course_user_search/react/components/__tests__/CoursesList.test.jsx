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
import {shallow, mount} from 'enzyme'
import {omit} from 'lodash'
import CoursesList from '../CoursesList'
import CoursesListRow from '../CoursesListRow'

describe('Account Course User Search CoursesList Sorting', () => {
  const coursesProps = {
    courses: [
      {
        id: '1',
        name: 'A',
        sis_course_id: 'SIS 1',
        workflow_state: 'alive',
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
        workflow_state: 'alive',
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
        workflow_state: 'alive',
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
        workflow_state: 'alive',
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
        workflow_state: 'alive',
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
        workflow_state: 'alive',
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
    course_name: 'Course',
    sis_course_id: 'SIS ID',
    term: 'Term',
    teacher: 'Teacher',
    subaccount: 'Sub-Account',
  }).forEach(([columnID, label]) => {
    test(`sorting by ${columnID} asc puts up-arrow on ${label} only`, () => {
      const wrapper = mount(
        <CoursesList
          {...{
            ...coursesProps,
            sort: columnID,
            order: 'asc',
          }}
        />
      )

      expect(wrapper.find('IconMiniArrowDownSolid')).toHaveLength(0)
      const upArrow = wrapper.find('IconMiniArrowUpSolid')
      expect(upArrow).toHaveLength(1)
      const header = upArrow.closest('CourseListHeader')

      const expectedTip =
        {
          course_name: 'Click to sort by name descending',
          total_students: 'Click to sort by number of students descending',
        }[columnID] || `Click to sort by ${label} descending`

      expect(header.find('Tooltip').first().prop('renderTip')).toMatch(RegExp(expectedTip, 'i'))
      expect(header.text()).toMatch(label)
    })

    test(`sorting by ${columnID} desc puts down-arrow on ${label} only`, () => {
      const wrapper = mount(
        <CoursesList
          {...{
            ...coursesProps,
            sort: columnID,
            order: 'desc',
          }}
        />
      )

      expect(wrapper.find('IconMiniArrowUpSolid')).toHaveLength(0)
      const downArrow = wrapper.find('IconMiniArrowDownSolid')
      expect(downArrow).toHaveLength(1)
      const header = downArrow.closest('CourseListHeader')

      const expectedTip =
        {
          course_name: 'Click to sort by name ascending',
          total_students: 'Click to sort by number of students ascending',
        }[columnID] || `Click to sort by ${label} ascending`

      expect(header.find('Tooltip').first().prop('renderTip')).toMatch(RegExp(expectedTip, 'i'))
      expect(header.text()).toMatch(label)
    })

    test(`clicking the ${label} column header calls onChangeSort with ${columnID}`, () => {
      const onChangeSort = jest.fn()
      const wrapper = mount(
        <CoursesList
          {...{
            ...coursesProps,
            onChangeSort,
          }}
        />
      )

      wrapper
        .find(`CourseListHeader`)
        .filterWhere(w => w.text().match(label))
        .find('button')
        .simulate('click')
      expect(onChangeSort).toHaveBeenCalledTimes(1)
      expect(onChangeSort).toHaveBeenCalledWith(columnID)
    })
  })

  test('displays SIS ID column if any course has one', () => {
    const wrapper = shallow(<CoursesList {...coursesProps} />)
    expect(wrapper.findWhere(n => n.prop('label') === 'SIS ID').exists()).toBeTruthy()
  })

  test(`doesn't display SIS ID column if no course has one`, () => {
    const propsWithoutSISids = {
      ...coursesProps,
      courses: coursesProps.courses.map(c => omit(c, ['sis_course_id'])),
    }
    const wrapper = shallow(<CoursesList {...propsWithoutSISids} />)
    expect(wrapper.findWhere(n => n.prop('label') === 'SIS ID').exists()).toBeFalsy()
  })

  test('displays courses in the right order', () => {
    const wrapper = shallow(<CoursesList {...coursesProps} />)
    const nodes = wrapper.find(CoursesListRow).getElements()

    expect(nodes[0].props.name).toBe('A')
    expect(nodes[1].props.name).toBe('Ba')
    expect(nodes[2].props.name).toBe('Bb')
    expect(nodes[3].props.name).toBe('C')
    expect(nodes[4].props.name).toBe('De')
    expect(nodes[5].props.name).toBe('Dz')

    expect(nodes[0].props.id).toBe('1')
    expect(nodes[1].props.id).toBe('2')
    expect(nodes[2].props.id).toBe('3')
    expect(nodes[3].props.id).toBe('4')
    expect(nodes[4].props.id).toBe('5')
    expect(nodes[5].props.id).toBe('6')
  })

  test('displays Terms in right order', () => {
    const nodes = shallow(<CoursesList {...coursesProps} />)
      .find(CoursesListRow)
      .getElements()

    expect(nodes[0].props.term.name).toBe('A Term')
    expect(nodes[1].props.term.name).toBe('Ba Term')
    expect(nodes[2].props.term.name).toBe('Bb Term')
    expect(nodes[3].props.term.name).toBe('C Term')
    expect(nodes[4].props.term.name).toBe('De Term')
    expect(nodes[5].props.term.name).toBe('Dz Term')
  })
})
