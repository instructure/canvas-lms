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

import {renderHook, act} from '@testing-library/react-hooks/dom'
import {useStudentAssignmentTray} from '../useStudentAssignmentTray'
import {MOCK_OUTCOMES, MOCK_STUDENTS} from '../../__fixtures__/rollups'
import {MOCK_ALIGNMENTS} from '../../__fixtures__/contributingScores'

describe('useStudentAssignmentTray', () => {
  const mockAlignments = MOCK_ALIGNMENTS.slice(0, 3)

  describe('initial state', () => {
    it('starts with tray closed', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      expect(result.current.isOpen).toBe(false)
      expect(result.current.state).toBeNull()
      expect(result.current.currentAlignment).toBeNull()
      expect(result.current.assignment).toBeNull()
    })

    it('provides default navigator states when closed', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      expect(result.current.assignmentNavigator).toEqual({
        hasNext: false,
        hasPrevious: false,
      })
      expect(result.current.studentNavigator).toEqual({
        hasNext: false,
        hasPrevious: false,
      })
    })
  })

  describe('open/close actions', () => {
    it('opens tray with provided data', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 1, mockAlignments)
      })

      expect(result.current.isOpen).toBe(true)
      expect(result.current.state).toEqual({
        outcome: MOCK_OUTCOMES[0],
        student: MOCK_STUDENTS[0],
        currentAlignmentIndex: 1,
        alignments: mockAlignments,
      })
    })

    it('closes tray and clears state', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 0, mockAlignments)
      })

      expect(result.current.isOpen).toBe(true)

      act(() => {
        result.current.close()
      })

      expect(result.current.isOpen).toBe(false)
      expect(result.current.state).toBeNull()
    })

    it('does not open if alignmentIndex is undefined', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], undefined as any, mockAlignments)
      })

      expect(result.current.isOpen).toBe(false)
    })
  })

  describe('derived data', () => {
    it('calculates current alignment correctly', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 1, mockAlignments)
      })

      expect(result.current.currentAlignment).toEqual(mockAlignments[1])
    })

    it('creates assignment object from current alignment', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 1, mockAlignments)
      })

      expect(result.current.assignment).toEqual({
        id: '2',
        name: 'Assignment 2',
        htmlUrl: '/courses/1/assignments/2',
      })
    })

    it('finds current student index', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[1], 0, mockAlignments)
      })

      expect(result.current.currentStudentIndex).toBe(1)
    })
  })

  describe('assignment navigation', () => {
    it('navigates to next assignment', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 0, mockAlignments)
      })

      expect(result.current.state?.currentAlignmentIndex).toBe(0)

      act(() => {
        result.current.handlers.navigateNextAssignment()
      })

      expect(result.current.state?.currentAlignmentIndex).toBe(1)
    })

    it('navigates to previous assignment', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 1, mockAlignments)
      })

      act(() => {
        result.current.handlers.navigatePreviousAssignment()
      })

      expect(result.current.state?.currentAlignmentIndex).toBe(0)
    })

    it('does not navigate beyond last assignment', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 2, mockAlignments)
      })

      act(() => {
        result.current.handlers.navigateNextAssignment()
      })

      expect(result.current.state?.currentAlignmentIndex).toBe(2)
    })

    it('does not navigate before first assignment', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 0, mockAlignments)
      })

      act(() => {
        result.current.handlers.navigatePreviousAssignment()
      })

      expect(result.current.state?.currentAlignmentIndex).toBe(0)
    })

    it('calculates assignment navigator states correctly', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      // At start
      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 0, mockAlignments)
      })
      expect(result.current.assignmentNavigator).toEqual({
        hasNext: true,
        hasPrevious: false,
      })

      // In middle
      act(() => {
        result.current.handlers.navigateNextAssignment()
      })
      expect(result.current.assignmentNavigator).toEqual({
        hasNext: true,
        hasPrevious: true,
      })

      // At end
      act(() => {
        result.current.handlers.navigateNextAssignment()
      })
      expect(result.current.assignmentNavigator).toEqual({
        hasNext: false,
        hasPrevious: true,
      })
    })
  })

  describe('student navigation', () => {
    it('navigates to next student and resets alignment index', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 2, mockAlignments)
      })

      act(() => {
        result.current.handlers.navigateNextStudent()
      })

      expect(result.current.state?.student).toEqual(MOCK_STUDENTS[1])
      expect(result.current.state?.currentAlignmentIndex).toBe(0)
    })

    it('navigates to previous student and resets alignment index', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[1], 2, mockAlignments)
      })

      act(() => {
        result.current.handlers.navigatePreviousStudent()
      })

      expect(result.current.state?.student).toEqual(MOCK_STUDENTS[0])
      expect(result.current.state?.currentAlignmentIndex).toBe(0)
    })

    it('does not navigate beyond last student', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))
      const lastStudent = MOCK_STUDENTS[MOCK_STUDENTS.length - 1]

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], lastStudent, 0, mockAlignments)
      })

      act(() => {
        result.current.handlers.navigateNextStudent()
      })

      expect(result.current.state?.student).toEqual(lastStudent)
    })

    it('does not navigate before first student', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 0, mockAlignments)
      })

      act(() => {
        result.current.handlers.navigatePreviousStudent()
      })

      expect(result.current.state?.student).toEqual(MOCK_STUDENTS[0])
    })

    it('calculates student navigator states correctly', () => {
      const {result} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 0, mockAlignments)
      })
      expect(result.current.studentNavigator).toEqual({
        hasNext: true,
        hasPrevious: false,
      })

      act(() => {
        result.current.handlers.navigateNextStudent()
      })
      expect(result.current.studentNavigator).toEqual({
        hasNext: true,
        hasPrevious: true,
      })

      act(() => {
        result.current.open(
          MOCK_OUTCOMES[0],
          MOCK_STUDENTS[MOCK_STUDENTS.length - 1],
          0,
          mockAlignments,
        )
      })
      expect(result.current.studentNavigator).toEqual({
        hasNext: false,
        hasPrevious: true,
      })
    })
  })

  describe('memoization', () => {
    it('maintains stable handler references across re-renders', () => {
      const {result, rerender} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      const firstHandlers = result.current.handlers
      const firstOpen = result.current.open
      const firstClose = result.current.close

      rerender()

      expect(result.current.handlers.navigateNextAssignment).toBe(
        firstHandlers.navigateNextAssignment,
      )
      expect(result.current.handlers.navigatePreviousAssignment).toBe(
        firstHandlers.navigatePreviousAssignment,
      )
      expect(result.current.handlers.navigateNextStudent).toBe(firstHandlers.navigateNextStudent)
      expect(result.current.handlers.navigatePreviousStudent).toBe(
        firstHandlers.navigatePreviousStudent,
      )
      expect(result.current.open).toBe(firstOpen)
      expect(result.current.close).toBe(firstClose)
    })

    it('maintains stable data references when state unchanged', () => {
      const {result, rerender} = renderHook(() => useStudentAssignmentTray(MOCK_STUDENTS))

      act(() => {
        result.current.open(MOCK_OUTCOMES[0], MOCK_STUDENTS[0], 1, mockAlignments)
      })

      const firstAssignment = result.current.assignment
      const firstAssignmentNavigator = result.current.assignmentNavigator
      const firstStudentNavigator = result.current.studentNavigator

      rerender()

      expect(result.current.assignment).toBe(firstAssignment)
      expect(result.current.assignmentNavigator).toBe(firstAssignmentNavigator)
      expect(result.current.studentNavigator).toBe(firstStudentNavigator)
    })
  })
})
