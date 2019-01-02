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
import {shallow} from 'enzyme'
import CoursesListRow from '../CoursesListRow'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip';

const props = {
  id: '1',
  name: 'A',
  showSISIds: false,
  sis_course_id: 'SIS 1',
  subaccount_name: 'dummy_value',
  total_students: 6,
  teachers: [
    {
      id: '1',
      name: 'Teacher, Testing',
      display_name: 'Testing Teacher'
    }
  ],
  term: {
    name: 'A Term'
  },
  workflow_state: 'alive'
}

it('indicates if a course is a blueprint course', () => {
  const tooltip = 'Tooltip[tip="This is a blueprint course"] IconBlueprint'
  expect(
    shallow(<CoursesListRow {...props} />)
      .find(tooltip)
      .exists()
  ).toBe(false)

  expect(
    shallow(<CoursesListRow {...props} blueprint />)
      .find(tooltip)
      .exists()
  ).toBe(true)
})

it('shows add-enrollment if it makes sense', () => {
  const tooltip = 'Tooltip[tip="Add Users to A"] IconPlus'
  expect(
    shallow(<CoursesListRow {...props} can_create_enrollments={true} />)
      .find(tooltip)
      .exists()
  ).toBe(true)
})

it('does not show add-enrollment when not allowed', () => {
  const tooltip = 'Tooltip[tip="Add Users to A"] IconPlus'
  expect(
    shallow(<CoursesListRow {...props}
                            can_create_enrollments={false} workflow_state='active' />)
      .find(tooltip)
      .exists()
  ).toBe(false)

  expect(
    shallow(<CoursesListRow {...props}
                            can_create_enrollments={true} workflow_state='completed'  />)
      .find(tooltip)
      .exists()
  ).toBe(false)
})

it('shows the teacher count when needed', () => {
  const wrapper = shallow(<CoursesListRow {...props} teacher_count={3} teachers={null} />)
  expect(wrapper.text()).toContain('3 teachers')
})
