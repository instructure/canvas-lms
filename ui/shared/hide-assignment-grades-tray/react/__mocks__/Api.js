/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

/* global vi */
const mockFn = typeof vi !== 'undefined' ? vi.fn : vi.fn

export const HIDE_ASSIGNMENT_GRADES = 'HIDE_ASSIGNMENT_GRADES'
export const HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS = 'HIDE_ASSIGNMENT_GRADES_FOR_SECTIONS'

export const hideAssignmentGrades = mockFn(() =>
  Promise.resolve({
    id: '1',
    workflowState: 'completed',
  }),
)
export const hideAssignmentGradesForSections = mockFn(() =>
  Promise.resolve({
    id: '1',
    workflowState: 'completed',
  }),
)
export const resolveHideAssignmentGradesStatus = mockFn(() => Promise.resolve({}))
