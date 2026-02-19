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

import {useState, useMemo, useCallback} from 'react'
import {Student, Outcome} from '@canvas/outcomes/react/types/rollup'
import {ContributingScoreAlignment} from '@canvas/outcomes/react/hooks/useContributingScores'

export interface StudentAssignmentTrayState {
  outcome: Outcome
  student: Student
  currentAlignmentIndex: number
  alignments: ContributingScoreAlignment[]
}

interface UseStudentAssignmentTrayResult {
  // State
  isOpen: boolean
  state: StudentAssignmentTrayState | null

  // Derived data
  currentAlignment: ContributingScoreAlignment | null
  assignment: {
    id: string
    name: string
    htmlUrl: string
  } | null
  assignmentNavigator: {
    hasNext: boolean
    hasPrevious: boolean
  }
  studentNavigator: {
    hasNext: boolean
    hasPrevious: boolean
  }
  currentStudentIndex: number

  // Actions
  open: (
    outcome: Outcome,
    student: Student,
    alignmentIndex: number,
    alignments: ContributingScoreAlignment[],
  ) => void
  close: () => void
  handlers: {
    navigateNextAssignment: () => void
    navigatePreviousAssignment: () => void
    navigateNextStudent: () => void
    navigatePreviousStudent: () => void
  }
}

export const useStudentAssignmentTray = (students: Student[]): UseStudentAssignmentTrayResult => {
  const [state, setState] = useState<StudentAssignmentTrayState | null>(null)

  const currentAlignment = useMemo(() => {
    if (!state) return null
    return state.alignments[state.currentAlignmentIndex]
  }, [state])

  const currentStudentIndex = useMemo(() => {
    if (!state) return -1
    return students.findIndex(s => s.id === state.student.id)
  }, [state, students])

  const assignment = useMemo(() => {
    if (!currentAlignment) return null
    return {
      id: currentAlignment.associated_asset_id,
      name: currentAlignment.associated_asset_name,
      htmlUrl: currentAlignment.html_url,
    }
  }, [currentAlignment])

  const assignmentNavigator = useMemo(() => {
    if (!state) {
      return {hasNext: false, hasPrevious: false}
    }
    return {
      hasNext: state.currentAlignmentIndex < state.alignments.length - 1,
      hasPrevious: state.currentAlignmentIndex > 0,
    }
  }, [state])

  const studentNavigator = useMemo(
    () => ({
      hasNext: currentStudentIndex >= 0 && currentStudentIndex < students.length - 1,
      hasPrevious: currentStudentIndex > 0,
    }),
    [currentStudentIndex, students.length],
  )

  const navigateNextAssignment = useCallback(() => {
    setState(prev => {
      if (!prev || prev.currentAlignmentIndex >= prev.alignments.length - 1) return prev
      return {...prev, currentAlignmentIndex: prev.currentAlignmentIndex + 1}
    })
  }, [])

  const navigatePreviousAssignment = useCallback(() => {
    setState(prev => {
      if (!prev || prev.currentAlignmentIndex <= 0) return prev
      return {...prev, currentAlignmentIndex: prev.currentAlignmentIndex - 1}
    })
  }, [])

  const navigateNextStudent = useCallback(() => {
    setState(prev => {
      if (!prev) return null
      const currentIndex = students.findIndex(s => s.id === prev.student.id)
      if (currentIndex < 0 || currentIndex >= students.length - 1) return prev
      return {
        ...prev,
        student: students[currentIndex + 1],
        currentAlignmentIndex: 0,
      }
    })
  }, [students])

  const navigatePreviousStudent = useCallback(() => {
    setState(prev => {
      if (!prev) return null
      const currentIndex = students.findIndex(s => s.id === prev.student.id)
      if (currentIndex <= 0) return prev
      return {
        ...prev,
        student: students[currentIndex - 1],
        currentAlignmentIndex: 0,
      }
    })
  }, [students])

  const open = useCallback(
    (
      outcome: Outcome,
      student: Student,
      alignmentIndex: number,
      alignments: ContributingScoreAlignment[],
    ) => {
      if (alignmentIndex === undefined) return
      setState({
        outcome,
        student,
        currentAlignmentIndex: alignmentIndex,
        alignments,
      })
    },
    [],
  )

  const close = useCallback(() => {
    setState(null)
  }, [])

  return {
    isOpen: state !== null,
    state,
    currentAlignment,
    assignment,
    assignmentNavigator,
    studentNavigator,
    currentStudentIndex,
    open,
    close,
    handlers: {
      navigateNextAssignment,
      navigatePreviousAssignment,
      navigateNextStudent,
      navigatePreviousStudent,
    },
  }
}
