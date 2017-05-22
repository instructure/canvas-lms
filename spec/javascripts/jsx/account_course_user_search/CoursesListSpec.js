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

define([
  'react',
  'enzyme',
  'jsx/account_course_user_search/CoursesList',
  'jsx/account_course_user_search/CoursesListRow'
], (React, {shallow}, CoursesList, CoursesListRow) => {
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
});
