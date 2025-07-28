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
import {render} from '@testing-library/react'
import CoursesListRow from '../CoursesListRow'

function renderRow(row) {
  return render(
    <table>
      <tbody>{row}</tbody>
    </table>,
  )
}

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
  workflow_state: 'available',
  concluded: false,
}

it('does not indicate a course is not blueprint course', () => {
  const {queryByText} = renderRow(<CoursesListRow {...props} />)

  expect(queryByText('This is a blueprint course')).toBeNull()
})

it('indicates if a course is a blueprint course', () => {
  const {getAllByText} = renderRow(<CoursesListRow {...props} blueprint={true} />)

  expect(getAllByText('This is a blueprint course').length).toBeGreaterThan(0)
})

it('filters addable roles by blueprint and permissions', () => {
  const ref = React.createRef()
  const wrapper = renderRow(
    <CoursesListRow
      ref={ref}
      {...props}
      blueprint={true}
      can_create_enrollments={true}
      concluded={false}
      roles={[
        {id: '1', base_role_name: 'TeacherEnrollment', addable_by_user: true},
        {id: '2', base_role_name: 'TaEnrollment', addable_by_user: true},
        {id: '3', base_role_name: 'StudentEnrollment', addable_by_user: true},
        {id: '4', base_role_name: 'ObserverEnrollment', addable_by_user: true},
        {id: '5', base_role_name: 'DesignerEnrollment', addable_by_user: false},
      ]}
    />,
  )
  const role_ids = ref.current
    .getAvailableRoles()
    .map(role => role.id)
    .sort()
  expect(role_ids).toEqual(['1', '2'])
})

it('does not indicate a course is a course template if it is not', () => {
  const {queryByText} = renderRow(<CoursesListRow {...props} />)
  expect(queryByText('This is a course template')).toBeNull()
})

it('indiates a course is a course template if it is', () => {
  const {getAllByText} = renderRow(<CoursesListRow {...props} template={true} />)
  expect(getAllByText('This is a course template').length).toBeGreaterThan(0)
})

it('shows add-enrollment if it makes sense', () => {
  const tooltip = 'Add Users to A'

  const {getAllByText} = renderRow(
    <CoursesListRow {...props} can_create_enrollments={true} concluded={false} />,
  )
  expect(getAllByText(tooltip).length).toBeGreaterThan(0)
})

it('does not show add-enrollment when not allowed', () => {
  const tooltip = 'Add Users to A'
  const {queryByText, rerender} = renderRow(
    <CoursesListRow
      {...props}
      can_create_enrollments={false}
      workflow_state="active"
      concluded={false}
    />,
  )
  expect(queryByText(tooltip)).toBeNull()
})

it('does not show add-enrollment when concluded', () => {
  const tooltip = 'Add Users to A'
  const {queryByText} = renderRow(
    <CoursesListRow
      {...props}
      can_create_enrollments={true}
      workflow_state="completed"
      concluded={true}
    />,
  )
  expect(queryByText(tooltip)).toBeNull()
})

it('does not show add-enrollment when a template course', () => {
  const tooltip = 'Add Users to A'
  const {queryByText} = renderRow(
    <CoursesListRow {...props} can_create_enrollments={true} template={true} />,
  )
  expect(queryByText(tooltip)).toBeNull()
})

it('shows the teacher count when needed', () => {
  const {getByText} = renderRow(<CoursesListRow {...props} teacher_count={3} teachers={null} />)
  expect(getByText('3 teachers', {exact: false})).toBeInTheDocument()
})

it('shows published icon and tooltip for published course', () => {
  const {queryAllByText} = renderRow(<CoursesListRow {...props} />)
  expect(queryAllByText('Published').length).toBeGreaterThan(0)
})

it('shows unpublished icon and tooltip for unpublished course', () => {
  const {queryAllByText} = renderRow(<CoursesListRow {...props} workflow_state="unpublished" />)
  expect(queryAllByText('Unpublished').length).toBeGreaterThan(0)
})

it('shows completed icon and tooltip for concluded course', () => {
  const {queryAllByText} = renderRow(<CoursesListRow {...props} workflow_state="completed" />)
  expect(queryAllByText('Concluded').length).toBeGreaterThan(0)
})
