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
import {shallow, mount} from 'enzyme'
import CoursesListRow from '../CoursesListRow'
import {renderRow} from '@canvas/util/react/testing/TableHelper'

const props = {
  id: '1',
  name: 'A',
  showSISIds: false,
  sis_course_id: 'SIS 1',
  subaccount_name: 'dummy_value',
  subaccount_id: '1',
  total_students: 6,
  teachers: [
    {
      id: '1',
      name: 'Teacher, Testing',
      display_name: 'Testing Teacher',
    },
  ],
  term: {
    name: 'A Term',
  },
  workflow_state: 'alive',
  concluded: false,
}

it('indicates if a course is a blueprint course', () => {
  const tooltip = 'Tooltip[renderTip="This is a blueprint course"] IconBlueprintLine'
  expect(
    shallow(<CoursesListRow {...props} />)
      .find(tooltip)
      .exists()
  ).toBe(false)

  expect(
    shallow(<CoursesListRow {...props} blueprint={true} />)
      .find(tooltip)
      .exists()
  ).toBe(true)
})

it('filters addable roles by blueprint and permissions', () => {
  const add_users_button = 'Tooltip[renderTip="Add Users to A"] IconButton'
  const wrapper = shallow(
    <CoursesListRow
      {...props}
      blueprint={true}
      can_create_enrollments={true}
      concluded={false}
      roles={[
        {id: '1', base_role_name: 'TeacherEnrollment', manageable_by_user: true},
        {id: '2', base_role_name: 'TaEnrollment', manageable_by_user: true},
        {id: '3', base_role_name: 'StudentEnrollment', manageable_by_user: true},
        {id: '4', base_role_name: 'ObserverEnrollment', manageable_by_user: true},
        {id: '5', base_role_name: 'DesignerEnrollment', manageable_by_user: false},
      ]}
    />
  )
  const role_ids = wrapper
    .instance()
    .getAvailableRoles()
    .map(role => role.id)
    .sort()
  expect(role_ids).toEqual(['1', '2'])
})

it('indicates if a course is a course template', () => {
  const tooltip = 'Tooltip[renderTip="This is a course template"] IconCollectionSolid'
  expect(
    shallow(<CoursesListRow {...props} />)
      .find(tooltip)
      .exists()
  ).toBe(false)

  expect(
    shallow(<CoursesListRow {...props} template={true} />)
      .find(tooltip)
      .exists()
  ).toBe(true)
})

it('shows add-enrollment if it makes sense', () => {
  const tooltip = 'Tooltip[renderTip="Add Users to A"] IconPlusLine'
  expect(
    shallow(<CoursesListRow {...props} can_create_enrollments={true} concluded={false} />)
      .find(tooltip)
      .exists()
  ).toBe(true)
})

it('does not show add-enrollment when not allowed', () => {
  const tooltip = 'Tooltip[renderTip="Add Users to A"] IconPlusLine'
  expect(
    shallow(
      <CoursesListRow
        {...props}
        can_create_enrollments={false}
        workflow_state="active"
        concluded={false}
      />
    )
      .find(tooltip)
      .exists()
  ).toBe(false)

  expect(
    shallow(
      <CoursesListRow
        {...props}
        can_create_enrollments={true}
        workflow_state="completed"
        concluded={true}
      />
    )
      .find(tooltip)
      .exists()
  ).toBe(false)

  expect(
    shallow(<CoursesListRow {...props} can_create_enrollments={true} template={true} />)
      .find(tooltip)
      .exists()
  ).toBe(false)
})

it('shows the teacher count when needed', () => {
  const wrapper = mount(renderRow(<CoursesListRow {...props} teacher_count={3} teachers={null} />))
  expect(wrapper.text()).toContain('3 teachers')
})
