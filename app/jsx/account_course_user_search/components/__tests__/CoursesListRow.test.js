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

const props = {
  id: '1',
  name: 'A',
  sis_course_id: 'SIS 1',
  workflow_state: 'alive',
  total_students: 6,
  teachers: [
    {
      id: '1',
      display_name: 'Testing Teacher'
    }
  ],
  term: {
    name: 'A Term'
  }
}

it('indicates if a course is a blueprint course', () => {
  const tooltip = 'Tooltip[tip="This is a blueprint course"] IconBlueprint'

  expect(
    shallow(<CoursesListRow {...props} />)
      .find(tooltip)
      .exists()
  ).toBeFalsy()

  expect(
    shallow(<CoursesListRow {...props} blueprint />)
      .find(tooltip)
      .exists()
  ).toBeTruthy()
})
