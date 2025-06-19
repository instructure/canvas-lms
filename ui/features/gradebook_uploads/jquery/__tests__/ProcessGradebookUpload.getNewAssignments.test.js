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

import ProcessGradebookUpload from '../process_gradebook_upload'

describe('ProcessGradebookUpload.getNewAssignmentsFromGradebook', () => {
  test('returns an empty array if the gradebook given has a single assignment with no id', () => {
    const gradebook = {assignments: [{key: 'value'}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(0)
  })

  test('returns an empty array if the gradebook given has a single assignment with a null id', () => {
    const gradebook = {assignments: [{id: null, key: 'value'}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(0)
  })

  test('returns an empty array if the gradebook given has a single assignment with positive id', () => {
    const gradebook = {assignments: [{id: 1}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(0)
  })

  test('returns an array with one assignment if the gradebook given has a single assignment with negative id', () => {
    const gradebook = {assignments: [{id: -1}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(1)
    expect(assignments[0].id).toBe(-1)
  })

  test('returns an array with one assignment if gradebook given has a single assignment with zero id', () => {
    const gradebook = {assignments: [{id: 0}]}
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(1)
    expect(assignments[0].id).toBe(0)
  })

  test('returns an array with only the assignments with non positive ids if the gradebook given has all ids', () => {
    const gradebook = {
      assignments: [{id: 0}, {id: -1}, {id: -2}, {id: 1}, {id: 2}, {id: null}, {key: 'value'}],
    }
    const assignments = ProcessGradebookUpload.getNewAssignmentsFromGradebook(gradebook)

    expect(assignments).toHaveLength(3)
    expect(assignments[0].id).toBe(0)
    expect(assignments[1].id).toBe(-1)
    expect(assignments[2].id).toBe(-2)
  })
})
