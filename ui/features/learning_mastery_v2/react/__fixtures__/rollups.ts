/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Outcome, Rating, Student} from '../types/rollup'

export const MOCK_STUDENTS: Student[] = [
  {
    id: '1',
    name: 'Student Test',
    display_name: 'Student Test',
    sortable_name: 'Test, Student',
    avatar_url: '/avatar-url',
    status: 'active',
  },
  {
    id: '2',
    name: 'Student Test 2',
    display_name: 'Student Test 2',
    sortable_name: 'Test 2, Student',
    avatar_url: '/avatar-url-2',
    status: 'inactive',
  },
  {
    id: '3',
    name: 'Student 3',
    display_name: 'Student 3',
    sortable_name: 'Student 3',
    avatar_url: '/avatar-url-3',
    status: 'concluded',
  },
]

export const MOCK_RATINGS: Rating[] = [
  {
    color: 'green',
    description: 'mastery!',
    mastery: true,
    points: 3,
  },
  {
    color: 'red',
    description: 'not great',
    mastery: false,
    points: 0,
  },
  {
    color: 'blue',
    description: 'great!',
    mastery: false,
    points: 5,
  },
]

export const MOCK_OUTCOMES: Outcome[] = [
  {
    id: '1',
    title: 'outcome 1',
    description: 'Outcome description',
    display_name: 'Friendly outcome name',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    points_possible: 5,
    mastery_points: 5,
    ratings: [MOCK_RATINGS[0], MOCK_RATINGS[1]],
  },
  {
    id: '2',
    title: 'outcome 2',
    description: 'Outcome description',
    display_name: 'Friendly outcome name',
    calculation_method: 'decaying_average',
    calculation_int: 65,
    points_possible: 5,
    mastery_points: 5,
    ratings: [MOCK_RATINGS[0], MOCK_RATINGS[1]],
  },
]
