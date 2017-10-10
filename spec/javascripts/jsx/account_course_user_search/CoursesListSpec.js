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
import {shallow} from 'enzyme'
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
  addUserUrls: {
    USER_LISTS_URL: 'http://courses/{{id}}/users',
    ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
  },
  roles: [{
    id: '1',
    course_id: '1',
    roles: [{
      base_role_type: 'StudentEnrollment'
    }]
  }]
}

test('renders with the proper urls and roles', () => {
  const wrapper = shallow(<CoursesList {...props} />)

  const renderedList = wrapper.find(CoursesListRow)
  const renderedUrls = renderedList.props().urls;
  deepEqual(renderedUrls, {
    USER_LISTS_URL: 'http://courses/123/users',
    ENROLL_USERS_URL: 'http://courses/123/users/enroll'
  }, 'it passed url props in and they were replaced properly');
});

QUnit.module('Account Course User Search CoursesList Sorting');

const coursesProps = {
  courses: [{
    id: '1',
    name: 'A',
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
  addUserUrls: {
    USER_LISTS_URL: 'http://courses/{{id}}/users',
    ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
  },
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
    const wrapper = shallow(<CoursesList {...{
      ...coursesProps,
      sort: columnID,
      order: 'asc'
    }} />)
    equal(wrapper.find('IconMiniArrowUpSolid').length, 0, 'no columns have an up arrow')
    const icons = wrapper.find('IconMiniArrowDownSolid')
    equal(icons.length, 1, 'only one down arrow')
    const header = icons.first().parents('Tooltip')
    let expectedTip = `Click to sort by ${label} descending`
    if (columnID === 'course_name') {
      expectedTip = 'Click to sort by name descending'
    }
    ok(header.prop('tip').match(RegExp(expectedTip, 'i')), 'has right tooltip')
    ok(header.contains(label), `${label} is the one that has the down arrow`)
  })

  test(`sorting by ${columnID} desc puts up-arrow on ${label} only`, () => {
    const wrapper = shallow(<CoursesList {...{
      ...coursesProps,
      sort: columnID,
      order: 'desc'
    }} />)
    equal(wrapper.find('IconMiniArrowDownSolid').length, 0)
    const icons = wrapper.find('IconMiniArrowUpSolid', 'no columns have a down arrow')
    equal(icons.length, 1, 'only one up arrow')
    const header = icons.first().parents('Tooltip')
    let expectedTip = `Click to sort by ${label} ascending`
    if (columnID === 'course_name') {
      expectedTip = 'Click to sort by name ascending'
    }
    ok(header.prop('tip').match(RegExp(expectedTip, 'i')), 'has right tooltip')
    ok(header.contains(label), `${label} is the one that has the up arrow`)
  })

  test(`clicking the ${label} column header calls onChangeSort with ${columnID}`, function() {
    const sortSpy = this.spy()
    const wrapper = shallow(<CoursesList {...{
      ...coursesProps,
      onChangeSort: sortSpy
    }} />)
    const header = wrapper.findWhere(n => n.text() === label).first().parents('Tooltip')
    header.simulate('click')
    ok(sortSpy.calledOnce)
    ok(sortSpy.calledWith(columnID))
  })
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
