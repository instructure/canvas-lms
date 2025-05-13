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

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck

import {createGradebook} from './GradebookSpecHelper'

describe('Gradebook suppressed assignments feature', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
  })

  const setup = (suppressFeatureEnabled, assignments) => {
    window.ENV.SETTINGS = {suppress_assignments: suppressFeatureEnabled}
    const assignmentGroup = {id: '12', assignments}
    gradebook.gotAllAssignmentGroups([assignmentGroup])
  }

  it('sets has_suppressed_assignments to true if any assignment is suppressed and feature is enabled', () => {
    setup(true, [
      {id: '35', name: 'An Assignment', due_at: null, suppress_assignment: true},
      {id: '36', name: 'Another Assignment', due_at: null, suppress_assignment: false},
    ])
    expect(gradebook.has_suppressed_assignments).toBe(true)
  })

  it('sets has_suppressed_assignments to false if no assignment is suppressed and feature is enabled', () => {
    setup(true, [
      {id: '35', name: 'An Assignment', due_at: null, suppress_assignment: false},
      {id: '36', name: 'Another Assignment', due_at: null, suppress_assignment: false},
    ])
    expect(gradebook.has_suppressed_assignments).toBe(false)
  })

  it('sets has_suppressed_assignments to false if feature is disabled', () => {
    setup(false, [
      {id: '35', name: 'An Assignment', due_at: null, suppress_assignment: true},
      {id: '36', name: 'Another Assignment', due_at: null, suppress_assignment: true},
    ])
    expect(gradebook.has_suppressed_assignments).toBe(false)
  })
})
