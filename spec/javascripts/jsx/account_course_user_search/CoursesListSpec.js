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
import ReactDOM from 'react-dom'
import {shallow, mount} from 'enzyme'
import {omit} from 'lodash'
import CoursesList from 'jsx/account_course_user_search/CoursesList'
import CoursesListRow from 'jsx/account_course_user_search/CoursesListRow'

QUnit.module('Account Course User Search CoursesList View');

const props = {
  courses: [{
    id: '123',
    name: 'this is a name',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }],
    term:{
      name: "Testing Term"
    }
  }],
  roles: [{
    id: '1',
    course_id: '1',
    roles: [{
      base_role_type: 'StudentEnrollment'
    }]
  }]
}

QUnit.module('Account Course User Search CoursesList Sorting');

const coursesProps = {
  courses: [{
    id: '1',
    name: 'A',
    sis_course_id: 'SIS 1',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }],
    term: {
      name: "A Term"
    }
  }, {
    id: '2',
    name: 'Ba',
    sis_course_id: 'SIS Ba',
    workflow_state: 'alive',
    total_students: 7,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }],
    term: {
      name: "Ba Term"
    }
  }, {
    id: '3',
    name: 'Bb',
    sis_course_id: 'SIS Bb',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }],
    term: {
      name: "Bb Term"
    }
  }, {
    id: '4',
    name: 'C',
    sis_course_id: 'SIS C',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }],
    term: {
      name: "C Term"
    }
  }, {
    id: '5',
    name: 'De',
    sis_course_id: 'SIS De',
    workflow_state: 'alive',
    total_students: 11,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }],
    term: {
      name: "De Term"
    }
  }, {
    id: '6',
    name: 'Dz',
    sis_course_id: 'SIS Dz',
    workflow_state: 'alive',
    total_students: 10,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }],
    term: {
      name: "Dz Term"
    }
  }],
  roles: [{
    id: '1',
    course_id: '1',
    roles: [{
      base_role_type: 'StudentEnrollment'
    }]
  }],
  sort: 'course_name',
  order: 'asc'
};

Object.entries({
  course_name: 'Course',
  sis_course_id: 'SIS ID',
  term: 'Term',
  teacher: 'Teacher',
  subaccount: 'Sub-Account',
  enrollments: 'Enrollments'
}).forEach(([columnID, label]) => {

  test(`sorting by ${columnID} asc puts down-arrow on ${label} only`, () => {
    const wrapper = mount(<CoursesList {...{
      ...coursesProps,
      sort: columnID,
      order: 'asc'
    }} />).getDOMNode()

    equal(wrapper.querySelectorAll('svg[name="IconMiniArrowUpSolid"]').length, 0, 'no columns have an up arrow')
    const icons = wrapper.querySelectorAll('svg[name=IconMiniArrowDownSolid]')
    equal(icons.length, 1, 'only one down arrow')
    const header = icons[0].parentNode

    const expectedTip = (columnID === 'course_name')
      ? 'Click to sort by name descending'
      : `Click to sort by ${label} descending`

    ok(header.textContent.match(RegExp(expectedTip, 'i')), 'has right tooltip')
    ok(header.textContent.match(label), `${label} is the one that has the down arrow`)
  })

  test(`sorting by ${columnID} desc puts up-arrow on ${label} only`, () => {
    const wrapper = mount(<CoursesList {...{
      ...coursesProps,
      sort: columnID,
      order: 'desc'
    }} />).getDOMNode()

    equal(wrapper.querySelectorAll('svg[name=IconMiniArrowDownSolid]').length, 0)
    const icons = wrapper.querySelectorAll('svg[name=IconMiniArrowUpSolid]', 'no columns have a down arrow')
    equal(icons.length, 1, 'only one up arrow')
    const header = icons[0].parentNode
    const expectedTip = (columnID === 'course_name')
      ? 'Click to sort by name ascending'
      : `Click to sort by ${label} ascending`

    ok(header.textContent.match(RegExp(expectedTip, 'i')), 'has right tooltip')
    ok(header.textContent.match(label), `${label} is the one that has the up arrow`)
  })

  test(`clicking the ${label} column header calls onChangeSort with ${columnID}`, function() {
    const wrapper = document.getElementById('fixtures')
    ReactDOM.render(<CoursesList {...{
      ...coursesProps,
      onChangeSort: this.mock().once().withArgs(columnID)
    }} />, wrapper)

    const header = Array.from(wrapper.querySelectorAll('[role=columnheader] button')).find(e => e.textContent.match(label))
    header.click()
  })
})

test('displays SIS ID column if any course has one', () => {
  const wrapper = shallow(<CoursesList {...coursesProps} />)
  ok(wrapper.findWhere(n => n.prop('label') === 'SIS ID').exists())
})

test(`doesn't display SIS ID column if no course has one`, () => {
  const propsWithoutSISids = {
    ...coursesProps,
    courses: coursesProps.courses.map(c => omit(c, ['sis_course_id']))
  }
  const wrapper = shallow(<CoursesList {...propsWithoutSISids} />)
  notOk(wrapper.findWhere(n => n.prop('label') === 'SIS ID').exists())
})

test('displays courses in the right order', () => {
  const wrapper = shallow(<CoursesList {...coursesProps} />)
  const renderedList = wrapper.find(CoursesListRow)

  equal(renderedList.nodes[0].props.name, 'A')
  equal(renderedList.nodes[1].props.name, 'Ba')
  equal(renderedList.nodes[2].props.name, 'Bb')
  equal(renderedList.nodes[3].props.name, 'C')
  equal(renderedList.nodes[4].props.name, 'De')
  equal(renderedList.nodes[5].props.name, 'Dz')

  equal(renderedList.nodes[0].props.id, '1')
  equal(renderedList.nodes[1].props.id, '2')
  equal(renderedList.nodes[2].props.id, '3')
  equal(renderedList.nodes[3].props.id, '4')
  equal(renderedList.nodes[4].props.id, '5')
  equal(renderedList.nodes[5].props.id, '6')
});

test('displays Terms in right order', () => {
  const renderedList = shallow(<CoursesList {...coursesProps} />).find(CoursesListRow)

  equal(renderedList.nodes[0].props.term.name, 'A Term')
  equal(renderedList.nodes[1].props.term.name, 'Ba Term')
  equal(renderedList.nodes[2].props.term.name, 'Bb Term')
  equal(renderedList.nodes[3].props.term.name, 'C Term')
  equal(renderedList.nodes[4].props.term.name, 'De Term')
  equal(renderedList.nodes[5].props.term.name, 'Dz Term')
})
