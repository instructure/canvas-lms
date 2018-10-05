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
import { shallow } from 'enzyme'
import AssignmentView from '../AssignmentView'

// using HOCs means we can't easily find these by string, so find them directly instead
import StudentView from '../../student/StudentView'
import TeacherView from '../../teacher/TeacherView'

const defaultEnv = () => ({
  ASSIGNMENT_ID: 42,
  PERMISSIONS: {
    context: {
      read_as_admin: false,
      manage_assignments: false,
    },
    assignment: {
      update: false,
      submit: false,
    }
  }
})

it('renders student view', () => {
  const env = defaultEnv()
  const wrapper = shallow(<AssignmentView env={env} /> )
  expect(wrapper.find(StudentView)).toHaveLength(1)
})

it('renders teacher view', () => {
  const env = defaultEnv()
  env.PERMISSIONS.context.read_as_admin = true
  const wrapper = shallow(<AssignmentView env={env} /> )
  expect(wrapper.find(TeacherView)).toHaveLength(1)
})
