/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Course} from './Course'
import gql from 'graphql-tag'
import {shape, string, bool} from 'prop-types'

export const Enrollment = {
  fragment: gql`
    fragment Enrollment on Enrollment {
      type
      course {
        ...Course
      }
      concluded
    }
    ${Course.fragment}
  `,

  shape: shape({
    type: string,
    course: Course.shape,
    concluded: bool,
  }),

  mock: ({type = 'StudentEnrollment', course = Course.mock(), concluded = false} = {}) => ({
    type,
    course,
    concluded,
    __typename: 'Enrollment',
  }),
}
