/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {
  mapAssignmentGroupQueryResults,
  sortAssignments,
  filterAssignmentsByStudent,
} from '../gradebookUtils'
import type {
  AssignmentConnection,
  AssignmentGroupConnection,
  AssignmentGradingPeriodMap,
  GradebookUserSubmissionDetails,
} from '../../types'
import {GradebookSortOrder} from '../../types'

describe('gradebookUtils', () => {
  // Shared helper functions for all tests
  const createAssignment = (
    id: string,
    name: string,
    overrides: Partial<AssignmentConnection> = {},
  ): AssignmentConnection => ({
    id,
    name,
    assignmentGroupId: '1',
    allowedAttempts: 1,
    anonymousGrading: false,
    anonymizeStudents: false,
    courseId: '1',
    dueAt: null,
    gradeGroupStudentsIndividually: false,
    gradesPublished: false,
    gradingType: 'points',
    htmlUrl: `/courses/1/assignments/${id}`,
    moderatedGrading: false,
    hasSubmittedSubmissions: false,
    omitFromFinalGrade: false,
    pointsPossible: 10,
    position: 1,
    postManually: false,
    submissionTypes: ['online_text_entry'],
    published: true,
    workflowState: 'published',
    gradingPeriodId: null,
    inClosedGradingPeriod: false,
    ...overrides,
  })

  const createAssignmentGroup = (
    id: string,
    assignments: AssignmentConnection[],
    position = 1,
  ): AssignmentGroupConnection => ({
    id,
    name: `Assignment Group ${id}`,
    groupWeight: 0,
    rules: {
      dropLowest: 0,
      dropHighest: 0,
      neverDrop: [],
    },
    sisId: null,
    state: 'available',
    position,
    assignmentsConnection: {
      nodes: assignments,
    },
  })

  const emptyGradingPeriodMap: AssignmentGradingPeriodMap = {}

  describe('mapAssignmentGroupQueryResults', () => {
    describe('without peer review sub assignments', () => {
      it('maps assignments correctly', () => {
        const assignment1 = createAssignment('1', 'Assignment 1')
        const assignment2 = createAssignment('2', 'Assignment 2')
        const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments).toHaveLength(2)
        expect(result.mappedAssignments[0].id).toBe('1')
        expect(result.mappedAssignments[0].name).toBe('Assignment 1')
        expect(result.mappedAssignments[1].id).toBe('2')
        expect(result.mappedAssignments[1].name).toBe('Assignment 2')
      })

      it('does not add isPeerReviewSubAssignment flag to regular assignments', () => {
        const assignment = createAssignment('1', 'Assignment 1')
        const assignmentGroup = createAssignmentGroup('1', [assignment])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments[0].isPeerReviewSubAssignment).toBeUndefined()
        expect(result.mappedAssignments[0].parentAssignmentId).toBeUndefined()
      })

      it('includes assignments in assignmentGroupMap', () => {
        const assignment1 = createAssignment('1', 'Assignment 1', {pointsPossible: 10})
        const assignment2 = createAssignment('2', 'Assignment 2', {pointsPossible: 20})
        const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignmentGroupMap['1'].assignments).toHaveLength(2)
        expect(result.mappedAssignmentGroupMap['1'].assignments[0].id).toBe('1')
        expect(result.mappedAssignmentGroupMap['1'].assignments[1].id).toBe('2')
      })
    })

    describe('with peer review sub assignments', () => {
      it('flattens peer review sub assignments after parent assignments', () => {
        const peerReviewSubAssignment = createAssignment('1-peer', 'Peer Review', {
          pointsPossible: 5,
        })
        const parentAssignment = createAssignment('1', 'Parent Assignment', {
          peerReviewSubAssignment,
        })
        const assignmentGroup = createAssignmentGroup('1', [parentAssignment])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments).toHaveLength(2)
        expect(result.mappedAssignments[0].id).toBe('1')
        expect(result.mappedAssignments[0].name).toBe('Parent Assignment')
        expect(result.mappedAssignments[1].id).toBe('1-peer')
        expect(result.mappedAssignments[1].name).toBe('Peer Review')
      })

      it('adds isPeerReviewSubAssignment flag to sub assignments', () => {
        const peerReviewSubAssignment = createAssignment('1-peer', 'Peer Review')
        const parentAssignment = createAssignment('1', 'Parent Assignment', {
          peerReviewSubAssignment,
        })
        const assignmentGroup = createAssignmentGroup('1', [parentAssignment])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments[1].isPeerReviewSubAssignment).toBe(true)
        expect(result.mappedAssignments[1].parentAssignmentId).toBe('1')
      })

      it('does not add isPeerReviewSubAssignment flag to parent assignments', () => {
        const peerReviewSubAssignment = createAssignment('1-peer', 'Peer Review')
        const parentAssignment = createAssignment('1', 'Parent Assignment', {
          peerReviewSubAssignment,
        })
        const assignmentGroup = createAssignmentGroup('1', [parentAssignment])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments[0].isPeerReviewSubAssignment).toBeUndefined()
        expect(result.mappedAssignments[0].parentAssignmentId).toBeUndefined()
      })

      it('adds visual indentation prefix to peer review sub assignment names', () => {
        const peerReviewSubAssignment = createAssignment('1-peer', 'Peer Review')
        const parentAssignment = createAssignment('1', 'Parent Assignment', {
          peerReviewSubAssignment,
        })
        const assignmentGroup = createAssignmentGroup('1', [parentAssignment])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments[1].name).toBe('Peer Review')
        // sortableName uses parent's name + parent ID + null to keep peer reviews adjacent to parents during sorting
        expect(result.mappedAssignments[1].sortableName).toBe('parent assignment\x001\x00')
      })

      it('includes both parent and peer review sub assignments in assignmentGroupMap', () => {
        const peerReviewSubAssignment = createAssignment('1-peer', 'Peer Review', {
          pointsPossible: 5,
        })
        const parentAssignment = createAssignment('1', 'Parent Assignment', {
          pointsPossible: 10,
          peerReviewSubAssignment,
        })
        const assignmentGroup = createAssignmentGroup('1', [parentAssignment])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignmentGroupMap['1'].assignments).toHaveLength(2)
        expect(result.mappedAssignmentGroupMap['1'].assignments[0].id).toBe('1')
        expect(result.mappedAssignmentGroupMap['1'].assignments[0].points_possible).toBe(10)
        expect(result.mappedAssignmentGroupMap['1'].assignments[1].id).toBe('1-peer')
        expect(result.mappedAssignmentGroupMap['1'].assignments[1].points_possible).toBe(5)
      })

      it('uses parent assignment grading period for peer review sub assignment', () => {
        const gradingPeriodMap: AssignmentGradingPeriodMap = {
          '1': 'gp-1',
        }
        const peerReviewSubAssignment = createAssignment('1-peer', 'Peer Review')
        const parentAssignment = createAssignment('1', 'Parent Assignment', {
          peerReviewSubAssignment,
        })
        const assignmentGroup = createAssignmentGroup('1', [parentAssignment])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], gradingPeriodMap)

        expect(result.mappedAssignments[0].gradingPeriodId).toBe('gp-1')
        expect(result.mappedAssignments[1].gradingPeriodId).toBe('gp-1')
      })

      it('handles multiple assignments with peer review sub assignments', () => {
        const peerReview1 = createAssignment('1-peer', 'Peer Review 1')
        const assignment1 = createAssignment('1', 'Assignment 1', {
          peerReviewSubAssignment: peerReview1,
        })
        const peerReview2 = createAssignment('2-peer', 'Peer Review 2')
        const assignment2 = createAssignment('2', 'Assignment 2', {
          peerReviewSubAssignment: peerReview2,
        })
        const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments).toHaveLength(4)
        expect(result.mappedAssignments[0].id).toBe('1')
        expect(result.mappedAssignments[1].id).toBe('1-peer')
        expect(result.mappedAssignments[2].id).toBe('2')
        expect(result.mappedAssignments[3].id).toBe('2-peer')
      })

      it('handles mixed assignments (some with peer review sub assignments, some without)', () => {
        const peerReview = createAssignment('1-peer', 'Peer Review')
        const assignment1 = createAssignment('1', 'Assignment 1', {
          peerReviewSubAssignment: peerReview,
        })
        const assignment2 = createAssignment('2', 'Assignment 2') // No peer review
        const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2])

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments).toHaveLength(3)
        expect(result.mappedAssignments[0].id).toBe('1')
        expect(result.mappedAssignments[1].id).toBe('1-peer')
        expect(result.mappedAssignments[1].isPeerReviewSubAssignment).toBe(true)
        expect(result.mappedAssignments[2].id).toBe('2')
        expect(result.mappedAssignments[2].isPeerReviewSubAssignment).toBeUndefined()
      })

      it('maintains assignment group position for peer review sub assignments', () => {
        const peerReviewSubAssignment = createAssignment('1-peer', 'Peer Review')
        const parentAssignment = createAssignment('1', 'Parent Assignment', {
          peerReviewSubAssignment,
        })
        const assignmentGroup = createAssignmentGroup('1', [parentAssignment], 5)

        const result = mapAssignmentGroupQueryResults([assignmentGroup], emptyGradingPeriodMap)

        expect(result.mappedAssignments[0].assignmentGroupPosition).toBe(5)
        expect(result.mappedAssignments[1].assignmentGroupPosition).toBe(5)
      })
    })

    describe('with multiple assignment groups', () => {
      it('maps assignments from multiple groups', () => {
        const assignment1 = createAssignment('1', 'Assignment 1')
        const assignment2 = createAssignment('2', 'Assignment 2')
        const group1 = createAssignmentGroup('1', [assignment1], 1)
        const group2 = createAssignmentGroup('2', [assignment2], 2)

        const result = mapAssignmentGroupQueryResults([group1, group2], emptyGradingPeriodMap)

        expect(result.mappedAssignments).toHaveLength(2)
        expect(result.mappedAssignmentGroupMap['1']).toBeDefined()
        expect(result.mappedAssignmentGroupMap['2']).toBeDefined()
      })

      it('handles peer review sub assignments across multiple groups', () => {
        const peerReview1 = createAssignment('1-peer', 'Peer Review 1')
        const assignment1 = createAssignment('1', 'Assignment 1', {
          peerReviewSubAssignment: peerReview1,
        })
        const peerReview2 = createAssignment('2-peer', 'Peer Review 2')
        const assignment2 = createAssignment('2', 'Assignment 2', {
          peerReviewSubAssignment: peerReview2,
        })
        const group1 = createAssignmentGroup('1', [assignment1], 1)
        const group2 = createAssignmentGroup('2', [assignment2], 2)

        const result = mapAssignmentGroupQueryResults([group1, group2], emptyGradingPeriodMap)

        expect(result.mappedAssignments).toHaveLength(4)
        expect(result.mappedAssignments[0].assignmentGroupPosition).toBe(1)
        expect(result.mappedAssignments[1].assignmentGroupPosition).toBe(1)
        expect(result.mappedAssignments[2].assignmentGroupPosition).toBe(2)
        expect(result.mappedAssignments[3].assignmentGroupPosition).toBe(2)
      })
    })
  })

  describe('sortAssignments with peer review sub assignments', () => {
    const createSortableAssignment = (
      id: string,
      name: string,
      dueDate: number,
      groupPosition: number,
      isPeerReview = false,
      parentId?: string,
      parentName?: string,
      position = 1,
    ) => ({
      id,
      name,
      assignmentGroupId: '1',
      allowedAttempts: 1,
      anonymousGrading: false,
      anonymizeStudents: false,
      courseId: '1',
      dueAt: null,
      gradeGroupStudentsIndividually: false,
      gradesPublished: false,
      gradingType: 'points' as const,
      htmlUrl: `/courses/1/assignments/${id}`,
      moderatedGrading: false,
      hasSubmittedSubmissions: false,
      omitFromFinalGrade: false,
      pointsPossible: 10,
      position,
      postManually: false,
      submissionTypes: ['online_text_entry'],
      published: true,
      workflowState: 'published' as const,
      gradingPeriodId: null,
      inClosedGradingPeriod: false,
      sortableName:
        isPeerReview && parentName && parentId
          ? `${parentName.toLowerCase()}\x00${parentId}\x00`
          : `${name.toLowerCase()}\x00${id}`,
      sortableDueDate: dueDate,
      assignmentGroupPosition: groupPosition,
      ...(isPeerReview && {isPeerReviewSubAssignment: true, parentAssignmentId: parentId}),
    })

    it('sorts alphabetically with peer review sub assignments adjacent to parents', () => {
      // Create assignments with peer reviews using actual implementation
      const peerReview1 = createAssignment('1-peer', 'Peer Review')
      const assignment1 = createAssignment('1', 'Zebra', {peerReviewSubAssignment: peerReview1})

      const peerReview2 = createAssignment('2-peer', 'Peer Review')
      const assignment2 = createAssignment('2', 'Apple', {peerReviewSubAssignment: peerReview2})

      const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2])
      const result = mapAssignmentGroupQueryResults([assignmentGroup], {})

      const sorted = sortAssignments(result.mappedAssignments, GradebookSortOrder.Alphabetical)

      // Peer reviews should sort adjacent to their parents using parent's name as sort key
      expect(sorted[0].id).toBe('2') // "Apple" (parent)
      expect(sorted[1].id).toBe('2-peer') // Peer review sorts right after Apple
      expect(sorted[2].id).toBe('1') // "Zebra" (parent)
      expect(sorted[3].id).toBe('1-peer') // Peer review sorts right after Zebra
    })

    it('sorts alphabetically with peer review sub assignments when parent names are identical', () => {
      // Create three assignments with identical names but different IDs
      const peerReview1 = createAssignment('101-peer', 'Peer Review')
      const assignment1 = createAssignment('101', 'REST Test Assignment', {
        peerReviewSubAssignment: peerReview1,
      })

      const peerReview2 = createAssignment('102-peer', 'Peer Review')
      const assignment2 = createAssignment('102', 'REST Test Assignment', {
        peerReviewSubAssignment: peerReview2,
      })

      const peerReview3 = createAssignment('103-peer', 'Peer Review')
      const assignment3 = createAssignment('103', 'REST Test Assignment', {
        peerReviewSubAssignment: peerReview3,
      })

      const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2, assignment3])
      const result = mapAssignmentGroupQueryResults([assignmentGroup], {})

      const sorted = sortAssignments(result.mappedAssignments, GradebookSortOrder.Alphabetical)

      // Each peer review should appear immediately after its parent, not grouped together
      expect(sorted[0].id).toBe('101') // First parent
      expect(sorted[1].id).toBe('101-peer') // First peer review
      expect(sorted[2].id).toBe('102') // Second parent
      expect(sorted[3].id).toBe('102-peer') // Second peer review
      expect(sorted[4].id).toBe('103') // Third parent
      expect(sorted[5].id).toBe('103-peer') // Third peer review
    })

    it('sorts by due date with peer review sub assignments', () => {
      const assignments = [
        createSortableAssignment('2', 'Assignment 2', 2000, 1),
        createSortableAssignment('2-peer', 'Peer Review', 2000, 1, true, '2', 'Assignment 2'),
        createSortableAssignment('1', 'Assignment 1', 1000, 1),
        createSortableAssignment('1-peer', 'Peer Review', 1000, 1, true, '1', 'Assignment 1'),
      ]

      const sorted = sortAssignments(assignments, GradebookSortOrder.DueDate)

      expect(sorted[0].sortableDueDate).toBe(1000)
      expect(sorted[1].sortableDueDate).toBe(1000)
      expect(sorted[2].sortableDueDate).toBe(2000)
      expect(sorted[3].sortableDueDate).toBe(2000)
    })

    it('sorts by assignment group with peer review sub assignments', () => {
      const assignments = [
        createSortableAssignment('2', 'Assignment 2', 1000, 2),
        createSortableAssignment('2-peer', 'Peer Review', 1000, 2, true, '2', 'Assignment 2'),
        createSortableAssignment('1', 'Assignment 1', 1000, 1),
        createSortableAssignment('1-peer', 'Peer Review', 1000, 1, true, '1', 'Assignment 1'),
      ]

      const sorted = sortAssignments(assignments, GradebookSortOrder.AssignmentGroup)

      expect(sorted[0].assignmentGroupPosition).toBe(1)
      expect(sorted[1].assignmentGroupPosition).toBe(1)
      expect(sorted[2].assignmentGroupPosition).toBe(2)
      expect(sorted[3].assignmentGroupPosition).toBe(2)
    })
  })

  describe('filterAssignmentsByStudent', () => {
    const createSubmission = (assignmentId: string): GradebookUserSubmissionDetails => ({
      assignmentId,
      cachedDueDate: null,
      deductedPoints: null,
      enteredGrade: null,
      excused: false,
      grade: null,
      gradeMatchesCurrentSubmission: true,
      id: `submission-${assignmentId}`,
      late: false,
      missing: false,
      redoRequest: false,
      score: null,
      state: 'unsubmitted',
      sticker: null,
      submittedAt: null,
      userId: 'user-1',
    })

    it('filters assignments to only those with submissions', () => {
      const assignment1 = createAssignment('1', 'Assignment 1')
      const assignment2 = createAssignment('2', 'Assignment 2')
      const assignment3 = createAssignment('3', 'Assignment 3')

      const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2, assignment3])
      const {mappedAssignments} = mapAssignmentGroupQueryResults(
        [assignmentGroup],
        emptyGradingPeriodMap,
      )

      const submissions = [createSubmission('1'), createSubmission('3')]

      const filtered = filterAssignmentsByStudent(mappedAssignments, submissions)

      expect(filtered).toHaveLength(2)
      expect(filtered[0].id).toBe('1')
      expect(filtered[1].id).toBe('3')
    })

    it('includes peer review sub assignments when parent has submission', () => {
      const peerReview = createAssignment('1-peer', 'Peer Review')
      const assignment1 = createAssignment('1', 'Assignment 1', {
        peerReviewSubAssignment: peerReview,
      })
      const assignment2 = createAssignment('2', 'Assignment 2')

      const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2])
      const {mappedAssignments} = mapAssignmentGroupQueryResults(
        [assignmentGroup],
        emptyGradingPeriodMap,
      )

      // Student only has submission for assignment 1 (parent), not for the peer review itself
      const submissions = [createSubmission('1')]

      const filtered = filterAssignmentsByStudent(mappedAssignments, submissions)

      expect(filtered).toHaveLength(2)
      expect(filtered[0].id).toBe('1')
      expect(filtered[1].id).toBe('1-peer')
      expect(filtered[1].isPeerReviewSubAssignment).toBe(true)
    })

    it('excludes peer review sub assignments when parent has no submission', () => {
      const peerReview = createAssignment('1-peer', 'Peer Review')
      const assignment1 = createAssignment('1', 'Assignment 1', {
        peerReviewSubAssignment: peerReview,
      })
      const assignment2 = createAssignment('2', 'Assignment 2')

      const assignmentGroup = createAssignmentGroup('1', [assignment1, assignment2])
      const {mappedAssignments} = mapAssignmentGroupQueryResults(
        [assignmentGroup],
        emptyGradingPeriodMap,
      )

      // Student only has submission for assignment 2
      const submissions = [createSubmission('2')]

      const filtered = filterAssignmentsByStudent(mappedAssignments, submissions)

      expect(filtered).toHaveLength(1)
      expect(filtered[0].id).toBe('2')
    })

    it('handles multiple peer review sub assignments correctly', () => {
      const peerReview1 = createAssignment('1-peer', 'Peer Review')
      const assignment1 = createAssignment('1', 'Assignment 1', {
        peerReviewSubAssignment: peerReview1,
      })

      const peerReview2 = createAssignment('2-peer', 'Peer Review')
      const assignment2 = createAssignment('2', 'Assignment 2', {
        peerReviewSubAssignment: peerReview2,
      })

      const assignment3 = createAssignment('3', 'Assignment 3')

      const assignmentGroup = createAssignmentGroup('1', [
        assignment1,
        assignment2,
        assignment3,
      ])
      const {mappedAssignments} = mapAssignmentGroupQueryResults(
        [assignmentGroup],
        emptyGradingPeriodMap,
      )

      // Student has submissions for assignments 1 and 3
      const submissions = [createSubmission('1'), createSubmission('3')]

      const filtered = filterAssignmentsByStudent(mappedAssignments, submissions)

      expect(filtered).toHaveLength(3)
      expect(filtered[0].id).toBe('1')
      expect(filtered[1].id).toBe('1-peer')
      expect(filtered[2].id).toBe('3')
    })

    it('throws error when peer review sub assignment is missing parentAssignmentId', () => {
      const peerReview = createAssignment('1-peer', 'Peer Review')
      const assignment = createAssignment('1', 'Assignment 1', {
        peerReviewSubAssignment: peerReview,
      })

      const assignmentGroup = createAssignmentGroup('1', [assignment])
      const {mappedAssignments} = mapAssignmentGroupQueryResults(
        [assignmentGroup],
        emptyGradingPeriodMap,
      )

      // Manually corrupt the peer review assignment to simulate missing parentAssignmentId
      const corruptedAssignments = mappedAssignments.map(a =>
        a.id === '1-peer' ? {...a, parentAssignmentId: undefined} : a,
      )

      const submissions = [createSubmission('1')]

      expect(() => {
        filterAssignmentsByStudent(corruptedAssignments, submissions)
      }).toThrow('Peer review sub assignment 1-peer is missing parentAssignmentId')
    })
  })
})
