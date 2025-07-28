/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {createGradebook, setFixtureHtml} from '../GradebookSpecHelper'

describe('Gradebook Data Loading: Content Load States', () => {
  let container
  let gradebook

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml(container)

    gradebook = createGradebook()
  })

  afterEach(() => {
    gradebook.destroy()
    container.remove()
  })

  describe('when Gradebook is instantiated', () => {
    test('sets assignments as "not loaded"', () => {
      expect(gradebook.contentLoadStates.assignmentsLoaded.all).toBe(false)
    })

    test('sets assignment groups as "not loaded"', () => {
      expect(gradebook.contentLoadStates.assignmentGroupsLoaded).toBe(false)
    })

    test('sets context modules as "not loaded"', () => {
      expect(gradebook.contentLoadStates.contextModulesLoaded).toBe(false)
    })

    test('sets custom columns as "not loaded"', () => {
      expect(gradebook.contentLoadStates.customColumnsLoaded).toBe(false)
    })

    test('sets grading period assignments as "not loaded"', () => {
      expect(gradebook.contentLoadStates.gradingPeriodAssignmentsLoaded).toBe(false)
    })

    test('sets student ids as "not loaded"', () => {
      expect(gradebook.contentLoadStates.studentIdsLoaded).toBe(false)
    })

    test('sets students as "not loaded"', () => {
      expect(gradebook.contentLoadStates.studentsLoaded).toBe(false)
    })

    test('sets submissions as "not loaded"', () => {
      expect(gradebook.contentLoadStates.submissionsLoaded).toBe(false)
    })
  })

  describe('#setAssignmentsLoaded()', () => {
    test('optionally sets assignments as "loaded"', () => {
      gradebook.setAssignmentsLoaded()
      expect(gradebook.contentLoadStates.assignmentsLoaded.all).toBe(true)
    })
  })

  describe('#setAssignmentGroupsLoaded()', () => {
    test('optionally sets assignment groups as "loaded"', () => {
      gradebook.setAssignmentGroupsLoaded(true)
      expect(gradebook.contentLoadStates.assignmentGroupsLoaded).toBe(true)
    })

    test('optionally sets assignment groups as "not loaded"', () => {
      gradebook.setAssignmentGroupsLoaded(true)
      gradebook.setAssignmentGroupsLoaded(false)
      expect(gradebook.contentLoadStates.assignmentGroupsLoaded).toBe(false)
    })
  })

  describe('#setGradingPeriodAssignmentsLoaded()', () => {
    test('optionally sets grading period assignments as "loaded"', () => {
      gradebook.setGradingPeriodAssignmentsLoaded(true)
      expect(gradebook.contentLoadStates.gradingPeriodAssignmentsLoaded).toBe(true)
    })

    test('optionally sets grading period assignments as "not loaded"', () => {
      gradebook.setGradingPeriodAssignmentsLoaded(true)
      gradebook.setGradingPeriodAssignmentsLoaded(false)
      expect(gradebook.contentLoadStates.gradingPeriodAssignmentsLoaded).toBe(false)
    })
  })

  describe('#setStudentIdsLoaded()', () => {
    test('optionally sets student ids as "loaded"', () => {
      gradebook.setStudentIdsLoaded(true)
      expect(gradebook.contentLoadStates.studentIdsLoaded).toBe(true)
    })

    test('optionally sets student ids as "not loaded"', () => {
      gradebook.setStudentIdsLoaded(true)
      gradebook.setStudentIdsLoaded(false)
      expect(gradebook.contentLoadStates.studentIdsLoaded).toBe(false)
    })
  })

  describe('#setStudentsLoaded()', () => {
    test('optionally sets students as "loaded"', () => {
      gradebook.setStudentsLoaded(true)
      expect(gradebook.contentLoadStates.studentsLoaded).toBe(true)
    })

    test('optionally sets students as "not loaded"', () => {
      gradebook.setStudentsLoaded(true)
      gradebook.setStudentsLoaded(false)
      expect(gradebook.contentLoadStates.studentsLoaded).toBe(false)
    })
  })

  describe('#setSubmissionsLoaded()', () => {
    test('optionally sets submissions as "loaded"', () => {
      gradebook.setSubmissionsLoaded(true)
      expect(gradebook.contentLoadStates.submissionsLoaded).toBe(true)
    })

    test('optionally sets submissions as "not loaded"', () => {
      gradebook.setSubmissionsLoaded(true)
      gradebook.setSubmissionsLoaded(false)
      expect(gradebook.contentLoadStates.submissionsLoaded).toBe(false)
    })
  })
})
