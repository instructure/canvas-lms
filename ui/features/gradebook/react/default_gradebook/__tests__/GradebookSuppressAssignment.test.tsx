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

describe('Gradebook showSuppressedAssignments toggle', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    window.ENV.SETTINGS = {suppress_assignments: true}
  })

  afterEach(() => {
    window.ENV.SETTINGS = {}
  })

  describe('gridDisplaySettings.showSuppressedAssignments', () => {
    it('defaults to false when setting is not provided', () => {
      expect(gradebook.gridDisplaySettings.showSuppressedAssignments).toBe(false)
    })

    it('initializes from gridDisplaySettings', () => {
      gradebook.gridDisplaySettings.showSuppressedAssignments = true
      expect(gradebook.gridDisplaySettings.showSuppressedAssignments).toBe(true)
    })
  })

  describe('filterAssignmentBySuppressStatus', () => {
    it('returns false for suppressed assignments when showSuppressedAssignments is false and feature is enabled', () => {
      window.ENV.SETTINGS = {suppress_assignments: true}
      gradebook.gridDisplaySettings.showSuppressedAssignments = false
      const assignment = {suppress_assignment: true}
      expect(gradebook.filterAssignmentBySuppressStatus(assignment)).toBe(false)
    })

    it('returns true for non-suppressed assignments when showSuppressedAssignments is false and feature is enabled', () => {
      window.ENV.SETTINGS = {suppress_assignments: true}
      gradebook.gridDisplaySettings.showSuppressedAssignments = false
      const assignment = {suppress_assignment: false}
      expect(gradebook.filterAssignmentBySuppressStatus(assignment)).toBe(true)
    })

    it('returns true for suppressed assignments when showSuppressedAssignments is true', () => {
      window.ENV.SETTINGS = {suppress_assignments: true}
      gradebook.gridDisplaySettings.showSuppressedAssignments = true
      const assignment = {suppress_assignment: true}
      expect(gradebook.filterAssignmentBySuppressStatus(assignment)).toBe(true)
    })

    it('returns true for all assignments when suppress_assignments feature is disabled', () => {
      window.ENV.SETTINGS = {suppress_assignments: false}
      gradebook.gridDisplaySettings.showSuppressedAssignments = false
      const suppressedAssignment = {suppress_assignment: true}
      const regularAssignment = {suppress_assignment: false}
      expect(gradebook.filterAssignmentBySuppressStatus(suppressedAssignment)).toBe(true)
      expect(gradebook.filterAssignmentBySuppressStatus(regularAssignment)).toBe(true)
    })

    it('returns true for all assignments when suppress_assignments setting is undefined', () => {
      window.ENV.SETTINGS = {}
      gradebook.gridDisplaySettings.showSuppressedAssignments = false
      const suppressedAssignment = {suppress_assignment: true}
      expect(gradebook.filterAssignmentBySuppressStatus(suppressedAssignment)).toBe(true)
    })

    it('returns false for peer review when parent assignment is suppressed and showSuppressedAssignments is false', () => {
      window.ENV.SETTINGS = {suppress_assignments: true}
      gradebook.gridDisplaySettings.showSuppressedAssignments = false
      const peerReview = {
        suppress_assignment: false,
        parent_assignment: {suppress_assignment: true},
      }
      expect(gradebook.filterAssignmentBySuppressStatus(peerReview)).toBe(false)
    })

    it('returns true for peer review when parent assignment is suppressed and showSuppressedAssignments is true', () => {
      window.ENV.SETTINGS = {suppress_assignments: true}
      gradebook.gridDisplaySettings.showSuppressedAssignments = true
      const peerReview = {
        suppress_assignment: false,
        parent_assignment: {suppress_assignment: true},
      }
      expect(gradebook.filterAssignmentBySuppressStatus(peerReview)).toBe(true)
    })
  })
})
