/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {GradingScheme, GradingSchemeTemplate} from '../../../index'

export const AccountGradingSchemes: GradingScheme[] = [
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 90}],
    id: '1',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 1',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Account',
    context_name: 'Test Account',
    data: [{name: 'A', value: 90}],
    id: '2',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 2',
  },
  {
    assessed_assignment: false,
    context_id: '1',
    context_type: 'Course',
    context_name: 'Test Course',
    data: [{name: 'A', value: 90}],
    id: '3',
    permissions: {manage: true},
    points_based: false,
    scaling_factor: 1,
    title: 'Grading Scheme 3',
  },
]

export const DefaultGradingScheme: GradingSchemeTemplate = {
  data: [{name: 'A', value: 90}],
  points_based: false,
  scaling_factor: 1,
  title: 'Default Grading Scheme',
}
