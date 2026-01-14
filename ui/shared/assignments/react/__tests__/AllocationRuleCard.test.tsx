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
import userEvent from '@testing-library/user-event'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import AllocationRuleCard from '../AllocationRuleCard'
import {AllocationRuleType} from '../../graphql/teacher/AssignmentTeacherTypes'

import {executeQuery} from '@canvas/graphql'

vi.mock('@canvas/graphql')

const mockExecuteQuery = vi.mocked(executeQuery)

describe('AllocationRuleCard', () => {
  const assessor = {
    _id: '1',
    name: 'Pikachu',
    peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
  }

  const assessee = {
    _id: '2',
    name: 'Piplup',
    peerReviewStatus: {mustReviewCount: 1, completedReviewsCount: 0},
  }

  const mockRefetchRules = vi.fn()

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    vi.clearAllMocks()
    mockExecuteQuery.mockResolvedValue({
      deleteAllocationRule: {
        allocationRuleId: '1',
      },
    })
  })

  const defaultRule: AllocationRuleType = {
    _id: '1',
    assessor,
    assessee,
    mustReview: true,
    reviewPermitted: true,
    appliesToAssessor: true,
  }

  const defaultProps = {
    rule: defaultRule,
    canEdit: false,
    assignmentId: '123',
    requiredPeerReviewsCount: 2,
    refetchRules: mockRefetchRules,
  }

  const renderWithProviders = (props = {}) => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    return render(
      <MockedQueryClientProvider client={queryClient}>
        <AllocationRuleCard {...defaultProps} {...props} />
      </MockedQueryClientProvider>,
    )
  }

  describe('Rule descriptions for assessor-focused rules', () => {
    it('displays "Must review" when mustReview is true and reviewPermitted is true', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: true,
        reviewPermitted: true,
        appliesToAssessor: true,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Pikachu')).toBeInTheDocument()
      expect(screen.getByText('Must review Piplup')).toBeInTheDocument()
    })

    it('displays "Must not review" when mustReview is true and reviewPermitted is false', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: true,
        reviewPermitted: false,
        appliesToAssessor: true,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Pikachu')).toBeInTheDocument()
      expect(screen.getByText('Must not review Piplup')).toBeInTheDocument()
    })

    it('displays "Should review" when mustReview is false and reviewPermitted is true', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: false,
        reviewPermitted: true,
        appliesToAssessor: true,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Pikachu')).toBeInTheDocument()
      expect(screen.getByText('Should review Piplup')).toBeInTheDocument()
    })

    it('displays "Should not review" when mustReview is false and reviewPermitted is false', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: false,
        reviewPermitted: false,
        appliesToAssessor: true,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Pikachu')).toBeInTheDocument()
      expect(screen.getByText('Should not review Piplup')).toBeInTheDocument()
    })
  })

  describe('Rule descriptions for assessee-focused rules', () => {
    it('displays "Must be reviewed by" when mustReview is true and reviewPermitted is true', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: true,
        reviewPermitted: true,
        appliesToAssessor: false,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Piplup')).toBeInTheDocument()
      expect(screen.getByText('Must be reviewed by Pikachu')).toBeInTheDocument()
    })

    it('displays "Must not be reviewed by" when mustReview is true and reviewPermitted is false', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: true,
        reviewPermitted: false,
        appliesToAssessor: false,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Piplup')).toBeInTheDocument()
      expect(screen.getByText('Must not be reviewed by Pikachu')).toBeInTheDocument()
    })

    it('displays "Should be reviewed by" when mustReview is false and reviewPermitted is true', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: false,
        reviewPermitted: true,
        appliesToAssessor: false,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Piplup')).toBeInTheDocument()
      expect(screen.getByText('Should be reviewed by Pikachu')).toBeInTheDocument()
    })

    it('displays "Should not be reviewed by" when mustReview is false and reviewPermitted is false', () => {
      const rule: AllocationRuleType = {
        _id: '1',
        assessor,
        assessee,
        mustReview: false,
        reviewPermitted: false,
        appliesToAssessor: false,
      }

      renderWithProviders({rule})

      expect(screen.getByText('Piplup')).toBeInTheDocument()
      expect(screen.getByText('Should not be reviewed by Pikachu')).toBeInTheDocument()
    })
  })

  describe('Action buttons', () => {
    describe('when user can edit allocation rules', () => {
      it('renders the edit button with correct accessibility label', () => {
        renderWithProviders({canEdit: true})
        const editButton = screen.getByTestId(`edit-rule-button-${defaultRule._id}`)

        expect(editButton).toBeInTheDocument()
        expect(screen.getByText(/^Edit Allocation Rule:/)).toBeInTheDocument()
      })

      it('renders the delete button with correct accessibility label', () => {
        renderWithProviders({canEdit: true})
        const deleteButton = screen.getByTestId('delete-allocation-rule-button')

        expect(deleteButton).toBeInTheDocument()
        expect(screen.getByText(/^Delete Allocation Rule:/)).toBeInTheDocument()
      })

      it('opens edit modal when edit button is clicked', async () => {
        renderWithProviders({canEdit: true})
        const editButton = screen.getByTestId(`edit-rule-button-${defaultRule._id}`)

        await user.click(editButton)

        expect(screen.getByText('Edit Rule')).toBeInTheDocument()
      })
    })

    describe('when user cannot edit allocation rules', () => {
      it('does not render the edit button', () => {
        renderWithProviders()
        const editButton = screen.queryByTestId(`edit-rule-button-${defaultRule._id}`)

        expect(editButton).not.toBeInTheDocument()
      })

      it('does not render the delete button', () => {
        renderWithProviders()
        const deleteButton = screen.queryByTestId('delete-allocation-rule-button')

        expect(deleteButton).not.toBeInTheDocument()
      })
    })
  })

  describe('Delete functionality', () => {
    it('calls handleRuleDelete on successful delete', async () => {
      const mockHandleRuleDelete = vi.fn()

      mockExecuteQuery.mockResolvedValueOnce({
        deleteAllocationRule: {
          allocationRuleId: '1',
        },
      })

      renderWithProviders({canEdit: true, handleRuleDelete: mockHandleRuleDelete})

      const deleteButton = screen.getByTestId('delete-allocation-rule-button')
      await user.click(deleteButton)

      await screen.findByText('Pikachu')

      expect(mockExecuteQuery).toHaveBeenCalledWith(expect.any(Object), {
        input: {ruleId: '1'},
      })
      expect(mockHandleRuleDelete).toHaveBeenCalledWith('1', 'Pikachu must review Piplup')
    })

    it('calls handleRuleDelete with error on delete failure', async () => {
      const mockHandleRuleDelete = vi.fn()
      const mockError = new Error('Allocation rule not found')

      mockExecuteQuery.mockRejectedValueOnce(mockError)

      renderWithProviders({canEdit: true, handleRuleDelete: mockHandleRuleDelete})

      const deleteButton = screen.getByTestId('delete-allocation-rule-button')
      await user.click(deleteButton)

      await screen.findByText('Pikachu')

      expect(mockExecuteQuery).toHaveBeenCalledWith(expect.any(Object), {
        input: {ruleId: '1'},
      })
      expect(mockHandleRuleDelete).toHaveBeenCalledWith('1', undefined, mockError)
    })

    it('calls handleRuleDelete with full rule description for screen reader announcement', async () => {
      const mockHandleRuleDelete = vi.fn()

      mockExecuteQuery.mockResolvedValueOnce({
        deleteAllocationRule: {
          allocationRuleId: '1',
        },
      })

      renderWithProviders({canEdit: true, handleRuleDelete: mockHandleRuleDelete})

      const deleteButton = screen.getByTestId('delete-allocation-rule-button')
      await user.click(deleteButton)

      await screen.findByText('Pikachu')

      // Verify handleRuleDelete is called with ruleId and full description
      expect(mockHandleRuleDelete).toHaveBeenCalledWith('1', 'Pikachu must review Piplup')
    })
  })
})
