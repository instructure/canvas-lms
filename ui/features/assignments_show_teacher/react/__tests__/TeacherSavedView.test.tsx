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
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import type {TeacherAssignmentType} from '@canvas/assignments/graphql/teacher/AssignmentTeacherTypes'
import TeacherSavedView from '../TeacherSavedView'

const mockUseModuleSequence = jest.fn()

jest.mock('../utils/getModuleItemId', () => ({
  __esModule: true,
  default: jest.fn(assignment => {
    if (assignment?.modules && assignment.modules.length > 0) {
      return assignment.modules[0].lid
    }
    return null
  }),
}))

jest.mock('../hooks/useModuleSequence', () => ({
  __esModule: true,
  default: (...args: any[]) => mockUseModuleSequence(...args),
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
  const renderWithQueryClient = (ui: React.ReactElement) => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    return render(<MockedQueryClientProvider client={queryClient}>{ui}</MockedQueryClientProvider>)
  }

  beforeEach(() => {
    jest.clearAllMocks()
    mockUseModuleSequence.mockReturnValue({
      isLoading: false,
      error: null,
      sequence: {
        next: null,
        previous: null,
      },
    })
  })

  describe('Assignment Header', () => {
    it('renders the assignment header with correct props', () => {
      const assignment = createMockAssignment({
        name: 'Math Homework',
      })
      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)

      expect(screen.getByTestId('assignment-header')).toBeInTheDocument()
      expect(screen.getByText('Math Homework')).toBeInTheDocument()
    })
  })

  describe('Peer Review Tabs', () => {
    beforeEach(() => {
      window.ENV.PEER_REVIEW_ALLOCATION_ENABLED = true
    })

    it('does not render AssignmentTabs when peer reviews are disabled', () => {
      const assignment = createMockAssignment({
        peerReviews: {
          enabled: false,
          count: 0,
        },
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-tab')).not.toBeInTheDocument()
      expect(screen.queryByTestId('peer-review-tab')).not.toBeInTheDocument()
    })

    it('does not render AssignmentTabs when PEER_REVIEW_ALLOCATION_ENABLED is false', () => {
      window.ENV.PEER_REVIEW_ALLOCATION_ENABLED = false
      const assignment = createMockAssignment({
        peerReviews: {
          enabled: true,
          count: 2,
        },
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-tab')).not.toBeInTheDocument()
      expect(screen.queryByTestId('peer-review-tab')).not.toBeInTheDocument()
    })

    it('renders AssignmentTabs when peer reviews are enabled and PEER_REVIEW_ALLOCATION_ENABLED is true', () => {
      const assignment = createMockAssignment({
        peerReviews: {
          enabled: true,
          count: 2,
        },
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignment-tab')).toBeInTheDocument()
      expect(screen.getByTestId('peer-review-tab')).toBeInTheDocument()
    })

    it('handles undefined peerReviews object gracefully', () => {
      const assignment = createMockAssignment({
        peerReviews: undefined,
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-tabs')).not.toBeInTheDocument()
      expect(screen.getByTestId('assignment-header')).toBeInTheDocument()
    })
  })

  describe('Assignment Details View', () => {
    beforeEach(() => {
      window.ENV.PEER_REVIEW_ALLOCATION_ENABLED = true
    })

    it('renders AssignmentDetailsView when peer reviews are disabled', () => {
      const assignment = createMockAssignment({
        description: 'This is the assignment description',
        peerReviews: {
          enabled: false,
          count: 0,
        },
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(screen.getByText('This is the assignment description')).toBeInTheDocument()
    })

    it('renders AssignmentDetailsView when PEER_REVIEW_ALLOCATION_ENABLED is false', () => {
      window.ENV.PEER_REVIEW_ALLOCATION_ENABLED = false
      const assignment = createMockAssignment({
        description: 'Another description',
        peerReviews: {
          enabled: true,
          count: 2,
        },
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(screen.getByText('Another description')).toBeInTheDocument()
    })

    it('renders AssignmentDetailsView inside tabs when tabs are rendered', () => {
      const assignment = createMockAssignment({
        description: 'Description inside tabs',
        peerReviews: {
          enabled: true,
          count: 2,
        },
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignment-tab')).toBeInTheDocument()
      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(screen.getByText('Description inside tabs')).toBeInTheDocument()
    })

    it('renders AssignmentDetailsView with empty description message when description is missing', () => {
      const assignment = createMockAssignment({
        description: '',
        peerReviews: {
          enabled: false,
          count: 0,
        },
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignments-2-assignment-description')).toBeInTheDocument()
      expect(
        screen.getByText('No additional details were added for this assignment.'),
      ).toBeInTheDocument()
    })
  })

  describe('Assignment Footer', () => {
    it('renders AssignmentFooter when module exists', () => {
      const assignment = createMockAssignment({
        modules: [{lid: '123', name: 'module'}],
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.getByTestId('assignment-footer')).toBeInTheDocument()
    })

    it('does not render AssignmentFooter when no modules exist', () => {
      const assignment = createMockAssignment({
        modules: [],
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-footer')).not.toBeInTheDocument()
    })

    it('does not render AssignmentFooter when modules is undefined', () => {
      const assignment = createMockAssignment({
        modules: undefined,
      })

      renderWithQueryClient(<TeacherSavedView assignment={assignment} breakpoints={{}} />)
      expect(screen.queryByTestId('assignment-footer')).not.toBeInTheDocument()
    })
  })
})
