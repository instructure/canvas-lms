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

import React from 'react'
import {render, screen} from '@testing-library/react'
import '@testing-library/jest-dom'
import type {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'
import TeacherSavedView from '../TeacherSavedView'

jest.mock('@canvas/assignments/react/AssignmentHeader', () => {
  return function MockAssignmentHeader({type, assignment}: any) {
    return (
      <div data-testid="assignment-header">
        <span>{assignment.name}</span>
      </div>
    )
  }
})

jest.mock('../components/AssignmentFooter', () => {
  return function MockAssignmentFooter({moduleItemId}: any) {
    return <div data-testid="assignment-footer">Assignment Footer - Item: {moduleItemId}</div>
  }
})

jest.mock('../components/AssignmentTabs', () => {
  return function MockAssignmentTabs() {
    return (
      <div data-testid="assignment-tabs">
        <button>Assignment</button>
        <button>Peer Review</button>
      </div>
    )
  }
})

jest.mock('../utils/getModuleItemId', () => ({
  __esModule: true,
  default: jest.fn(assignment => {
    if (assignment?.modules && assignment.modules.length > 0) {
      return assignment.modules[0].lid
    }
    return null
  }),
}))

const createMockAssignment = (
  overrides: Partial<TeacherAssignmentType> = {},
): TeacherAssignmentType =>
  ({
    id: '1',
    gid: 'assignment_1',
    name: 'Test Assignment',
    description: 'Test Description',
    pointsPossible: 100,
    dueAt: null,
    lockAt: null,
    unlockAt: null,
    state: 'published',
    course: {
      id: 'course_1',
      name: 'Test Course',
    },
    peerReviews: {
      enabled: false,
    },
    modules: [],
    ...overrides,
  }) as TeacherAssignmentType

describe('TeacherSavedView', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Assignment Header', () => {
    it('renders the assignment header with correct props', () => {
      const assignment = createMockAssignment({
        name: 'Math Homework',
      })
      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)

      expect(screen.getByTestId('assignment-header')).toBeInTheDocument()
      expect(screen.getByText('Math Homework')).toBeInTheDocument()
    })
  })

  describe('Peer Review Tabs', () => {
    beforeEach(() => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = true
    })

    it('does not render AssignmentTabs when peer reviews are disabled', () => {
      const assignment = createMockAssignment({
        peerReviews: {
          enabled: false,
        },
      })

      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-tabs')).not.toBeInTheDocument()
    })

    it('does not render AssignmentTabs when PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED is false', () => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = false
      const assignment = createMockAssignment({
        peerReviews: {
          enabled: true,
        },
      })

      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-tabs')).not.toBeInTheDocument()
    })

    it('renders AssignmentTabs when peer reviews are enabled and PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED is true', () => {
      const assignment = createMockAssignment({
        peerReviews: {
          enabled: true,
        },
      })

      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignment-tabs')).toBeInTheDocument()
      expect(screen.getByText('Assignment')).toBeInTheDocument()
      expect(screen.getByText('Peer Review')).toBeInTheDocument()
    })

    it('handles undefined peerReviews object gracefully', () => {
      const assignment = createMockAssignment({
        peerReviews: undefined,
      })

      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-tabs')).not.toBeInTheDocument()
      expect(screen.getByTestId('assignment-header')).toBeInTheDocument()
    })
  })

  describe('Assignment Footer', () => {
    it('renders AssignmentFooter when module exists', () => {
      const assignment = createMockAssignment({
        modules: [{lid: '123', name: 'module'}],
      })

      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignment-footer')).toBeInTheDocument()
      expect(screen.getByText('Assignment Footer - Item: 123')).toBeInTheDocument()
    })

    it('does not render AssignmentFooter when no modules exist', () => {
      const assignment = createMockAssignment({
        modules: [],
      })

      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-footer')).not.toBeInTheDocument()
    })

    it('does not render AssignmentFooter when modules is undefined', () => {
      const assignment = createMockAssignment({
        modules: undefined,
      })

      render(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-footer')).not.toBeInTheDocument()
    })
  })
})
