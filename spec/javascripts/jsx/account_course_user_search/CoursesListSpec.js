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
    }]
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
};

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
    }]
  },
  {
    id: '2',
    name: 'Ba',
    workflow_state: 'alive',
    total_students: 7,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  },
  {
    id: '3',
    name: 'Bb',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  },
  {
    id: '4',
    name: 'C',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  },
  {
    id: '5',
    name: 'De',
    workflow_state: 'alive',
    total_students: 11,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  },
  {
    id: '6',
    name: 'Dz',
    workflow_state: 'alive',
    total_students: 10,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
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

test('displays courses that are passed in as props', () => {

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

test('sorting by course name ascending puts down-arrow on Name', () => {
  const wrapper = shallow(<CoursesList {...coursesProps} />)
  const header = wrapper.find('a')
  equal(header.nodes[0].props.children.props.children[1].type.name, 'IconArrowDownSolid')
});


const descIdSinonProps = {
  courses: [{
    id: '1',
    name: 'A',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  }],
  addUserUrls: {
    USER_LISTS_URL: 'http://courses/{{id}}/users',
    ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
  },
  sort: 'sis_course_id',
  order: 'desc',
  onChangeSort: sinon.spy(),
};

test('sorting by id descending puts up-arrow on SIS ID', () => {
  const wrapper = shallow(<CoursesList {...descIdSinonProps} />)
  const header = wrapper.find('a')
  equal(header.nodes[1].props.children.props.children[1].type.name, 'IconArrowUpSolid')
});

test('clicking the Courses column header calls onChangeSort with course_name', () => {
  const wrapper = shallow(<CoursesList {...descIdSinonProps} />)
  const header = wrapper.find('a').first()
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onChangeSort
  ok(sinonCallback.calledOnce)
  ok(sinonCallback.calledWith('course_name'))
});


const moreSinonProps = {
  courses: [{
    id: '1',
    name: 'A',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  }],
  addUserUrls: {
    USER_LISTS_URL: 'http://courses/{{id}}/users',
    ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
  },
  sort: 'sis_course_id',
  order: 'desc',
  onChangeSort: sinon.spy(),
};

test('clicking the SIS ID column header calls onChangeSort with sis_source_id', () => {
  const wrapper = shallow(<CoursesList {...moreSinonProps} />)
  const header = wrapper.find('a').slice(1, 2)
  header.simulate('click')
  header.simulate('click')
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onChangeSort
  ok(sinonCallback.callCount === 3)
  ok(sinonCallback.calledWith('sis_course_id'))
});

const teacherSinonProps = {
  courses: [{
    id: '1',
    name: 'A',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  }],
  addUserUrls: {
    USER_LISTS_URL: 'http://courses/{{id}}/users',
    ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
  },
  sort: 'teacher',
  order: 'asc',
  onChangeSort: sinon.spy(),
};

test('sorting by teacher ascending puts down-arrow on Teacher', () => {
  const wrapper = shallow(<CoursesList {...teacherSinonProps} />)
  const header = wrapper.find('a')
  equal(header.nodes[2].props.children.props.children[1].type.name, 'IconArrowDownSolid')
});

test('clicking the Teacher column header calls onChangeSort with teacher', () => {
  const wrapper = shallow(<CoursesList {...teacherSinonProps} />)
  const header = wrapper.find('a').slice(2, 3)
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onChangeSort
  ok(sinonCallback.calledOnce)
  ok(sinonCallback.calledWith('teacher'))
});

const subaccountSinonProps = {
  courses: [{
    id: '1',
    name: 'A',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  }],
  addUserUrls: {
    USER_LISTS_URL: 'http://courses/{{id}}/users',
    ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
  },
  sort: 'subaccount',
  order: 'asc',
  onChangeSort: sinon.spy(),
};

test('sorting by subaccount ascending puts down-arrow on Enrollments', () => {
  const wrapper = shallow(<CoursesList {...subaccountSinonProps} />)
  const header = wrapper.find('a')
  equal(header.nodes[3].props.children.props.children[1].type.name, 'IconArrowDownSolid')
});

test('clicking the Enrollments column header calls onChangeSort with enrollments', () => {
  const wrapper = shallow(<CoursesList {...subaccountSinonProps} />)
  const header = wrapper.find('a').slice(3, 4)
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onChangeSort
  ok(sinonCallback.calledOnce)
  ok(sinonCallback.calledWith('subaccount'))
});

const enrollmentsSinonProps = {
  courses: [{
    id: '1',
    name: 'A',
    workflow_state: 'alive',
    total_students: 6,
    teachers: [{
      id: '1',
      display_name: 'Testing Teacher'
    }]
  }],
  addUserUrls: {
    USER_LISTS_URL: 'http://courses/{{id}}/users',
    ENROLL_USERS_URL: 'http://courses/{{id}}/users/enroll'
  },
  sort: 'enrollments',
  order: 'asc',
  onChangeSort: sinon.spy(),
};

test('sorting by enrollments ascending puts down-arrow on Enrollments', () => {
  const wrapper = shallow(<CoursesList {...enrollmentsSinonProps} />)
  const header = wrapper.find('a')
  equal(header.nodes[4].props.children.props.children[1].type.name, 'IconArrowDownSolid')
});

test('clicking the Enrollments column header calls onChangeSort with enrollments', () => {
  const wrapper = shallow(<CoursesList {...enrollmentsSinonProps} />)
  const header = wrapper.find('a').slice(4, 5)
  header.simulate('click')

  const sinonCallback = wrapper.unrendered.props.onChangeSort
  ok(sinonCallback.calledOnce)
  ok(sinonCallback.calledWith('enrollments'))
});
