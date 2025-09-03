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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import CreateEditAllocationRuleModal from '../CreateEditAllocationRuleModal'
import {type AllocationRuleType} from '../AllocationRuleCard'
import {CourseStudent} from '../../graphql/hooks/useAssignedStudents'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

const {executeQuery} = require('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

const mockStudents: CourseStudent[] = [
  {_id: '1', name: 'Student 1'},
  {_id: '2', name: 'Student 2'},
  {_id: '3', name: 'Student 3'},
]

describe('CreateEditAllocationRuleModal', () => {
  const mockSetIsOpen = jest.fn()
  const defaultProps = {
    isOpen: true,
    setIsOpen: mockSetIsOpen,
  }

  const reviewer: CourseStudent = {
    _id: '1',
    name: 'Pikachu',
  }

  const reviewee: CourseStudent = {
    _id: '2',
    name: 'Piplup',
  }

  const sampleRule: AllocationRuleType = {
    id: '1',
    reviewer,
    reviewee,
    mustReview: true,
    reviewPermitted: true,
    appliesToReviewer: true,
  }

  let user: ReturnType<typeof userEvent.setup>

  beforeEach(() => {
    user = userEvent.setup()
    jest.clearAllMocks()
  })

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
        <CreateEditAllocationRuleModal {...defaultProps} {...props} />
      </MockedQueryClientProvider>,
    )
  }

  describe('Modal rendering', () => {
    it('renders create modal when isEdit is false', () => {
      renderWithProviders()

      expect(screen.getByText('Create Rule')).toBeInTheDocument()
      expect(screen.getByTestId('create-rule-modal')).toBeInTheDocument()
    })

    it('renders edit modal when isEdit is true', () => {
      renderWithProviders({isEdit: true, rule: sampleRule})

      expect(screen.getByText('Edit Rule')).toBeInTheDocument()
      expect(screen.getByTestId('edit-rule-modal')).toBeInTheDocument()
    })

    it('does not render when isOpen is false', () => {
      renderWithProviders({isOpen: false})

      expect(screen.queryByTestId('create-rule-modal')).not.toBeInTheDocument()
      expect(screen.queryByTestId('edit-rule-modal')).not.toBeInTheDocument()
    })
  })

  describe('Target type selection', () => {
    beforeEach(() => {
      renderWithProviders()
    })

    it('renders target type radio options', () => {
      expect(screen.getByTestId('target-type-reviewer')).toBeInTheDocument()
      expect(screen.getByTestId('target-type-reviewee')).toBeInTheDocument()
      expect(screen.getByTestId('target-type-reciprocal')).toBeInTheDocument()
    })

    it('defaults to reviewer target type', () => {
      const reviewerRadio = screen.getByTestId('target-type-reviewer')
      expect(reviewerRadio).toBeChecked()
    })

    it('changes labels when target type changes', async () => {
      const revieweeRadio = screen.getByTestId('target-type-reviewee')

      await user.click(revieweeRadio)

      expect(screen.getByText('Recipient Name')).toBeInTheDocument()
      expect(screen.getByText('Reviewer Name')).toBeInTheDocument()
    })
  })

  describe('Review type selection', () => {
    beforeEach(() => {
      renderWithProviders()
    })

    it('renders all review type options', () => {
      expect(screen.getByTestId('review-type-must-review')).toBeInTheDocument()
      expect(screen.getByTestId('review-type-must-not-review')).toBeInTheDocument()
      expect(screen.getByTestId('review-type-should-review')).toBeInTheDocument()
      expect(screen.getByTestId('review-type-should-not-review')).toBeInTheDocument()
    })

    it('defaults to "Must review"', () => {
      const mustReviewRadio = screen.getByTestId('review-type-must-review')
      expect(mustReviewRadio).toBeChecked()
    })

    it('allows selection of different review types', async () => {
      const shouldReviewRadio = screen.getByTestId('review-type-should-review')

      await user.click(shouldReviewRadio)

      expect(shouldReviewRadio).toBeChecked()
      expect(screen.getByTestId('review-type-must-review')).not.toBeChecked()
    })
  })

  describe('Student selection', () => {
    beforeEach(() => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          assignedStudents: {
            nodes: mockStudents,
          },
        },
      })
      renderWithProviders()
    })

    it('renders reviewer and recipient select fields', () => {
      expect(screen.getByText('Reviewer Name')).toBeInTheDocument()
      expect(screen.getByText('Recipient Name')).toBeInTheDocument()
    })

    it('shows student options when typing in select field', async () => {
      const reviewerSelect = screen.getByText('Reviewer Name').querySelector('input')

      if (reviewerSelect) {
        await user.type(reviewerSelect, 'Student 1')

        await waitFor(() => {
          expect(screen.getByText('Student 1')).toBeInTheDocument()
        })
      }
    })
  })

  describe('Additional subject fields', () => {
    beforeEach(() => {
      renderWithProviders()
    })

    it('shows add another recipient button', () => {
      expect(screen.getByTestId('add-subject-button')).toBeInTheDocument()
    })

    it('adds additional subject field when button is clicked', async () => {
      const addButton = screen.getByTestId('add-subject-button')

      await user.click(addButton)

      await waitFor(() => {
        // Look for the additional field by its label instead
        expect(screen.getAllByText('Recipient Name')).toHaveLength(2)
      })
    })

    it('shows delete button for additional fields', async () => {
      const addButton = screen.getByTestId('add-subject-button')

      await user.click(addButton)

      await waitFor(() => {
        expect(screen.getByTestId('delete-additional-subject-field-1-button')).toBeInTheDocument()
      })
    })

    it('removes additional field when delete button is clicked', async () => {
      const addButton = screen.getByTestId('add-subject-button')

      await user.click(addButton)

      await waitFor(() => {
        const deleteButton = screen.getByTestId('delete-additional-subject-field-1-button')
        expect(deleteButton).toBeInTheDocument()
      })

      const deleteButton = screen.getByTestId('delete-additional-subject-field-1-button')
      await user.click(deleteButton)

      await waitFor(() => {
        expect(
          screen.queryByTestId('delete-additional-subject-field-1-button'),
        ).not.toBeInTheDocument()
        expect(screen.getAllByText('Recipient Name')).toHaveLength(1)
      })
    })
  })

  describe('Form validation', () => {
    beforeEach(() => {
      renderWithProviders()
    })

    it('shows validation errors when required fields are empty', async () => {
      const saveButton = screen.getByTestId('save-button')

      await user.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('Reviewer is required')).toBeInTheDocument()
        expect(screen.getByText('Recipient is required')).toBeInTheDocument()
      })
    })

    it('validates additional subject fields', async () => {
      const addButton = screen.getByTestId('add-subject-button')
      const saveButton = screen.getByTestId('save-button')

      await user.click(addButton)
      await user.click(saveButton)

      await waitFor(() => {
        const errorMessages = screen.getAllByText('Recipient is required')
        expect(errorMessages.length).toBeGreaterThan(1)
      })
    })
  })

  describe('Edit mode', () => {
    it('populates fields with existing rule data', () => {
      renderWithProviders({isEdit: true, rule: sampleRule})

      expect(screen.getByTestId('target-type-reviewer')).toBeChecked()
      expect(screen.getByTestId('review-type-must-review')).toBeChecked()
      expect(screen.getByDisplayValue('Pikachu')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Piplup')).toBeInTheDocument()
    })

    it('populates fields for reviewee-focused rule', () => {
      const revieweeRule: AllocationRuleType = {
        ...sampleRule,
        appliesToReviewer: false,
        mustReview: false,
        reviewPermitted: true,
      }

      renderWithProviders({isEdit: true, rule: revieweeRule})

      expect(screen.getByTestId('target-type-reviewee')).toBeChecked()
      expect(screen.getByTestId('review-type-should-review')).toBeChecked()
    })
  })

  describe('Modal actions', () => {
    beforeEach(() => {
      renderWithProviders()
    })

    it('closes modal when cancel button is clicked', async () => {
      const cancelButton = screen.getByTestId('cancel-button')

      await user.click(cancelButton)

      await waitFor(() => {
        expect(mockSetIsOpen).toHaveBeenCalledWith(false)
      })
    })

    it('calls setIsOpen with false when save is successful', async () => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          assignedStudents: {
            nodes: mockStudents,
          },
        },
      })

      const reviewerInput = screen.getAllByText('Reviewer Name')[0].querySelector('input')
      const recipientInput = screen.getAllByText('Recipient Name')[0].querySelector('input')

      if (reviewerInput && recipientInput) {
        await user.type(reviewerInput, 'Student 1')
        await user.click(screen.getByText('Student 1'))

        await user.type(recipientInput, 'Student 2')
        await user.click(screen.getByText('Student 2'))

        const saveButton = screen.getByTestId('save-button')
        await user.click(saveButton)

        await waitFor(() => {
          expect(mockSetIsOpen).toHaveBeenCalledWith(false)
        })
      }
    })
  })

  describe('Accessibility', () => {
    beforeEach(() => {
      renderWithProviders()
    })

    it('provides correct aria-label for add subject button based on target type', async () => {
      const addButton = screen.getByTestId('add-subject-button')
      expect(addButton).toHaveAttribute('aria-label', 'Add another recipient name')

      const revieweeRadio = screen.getByTestId('target-type-reviewee')
      await user.click(revieweeRadio)

      await waitFor(() => {
        expect(addButton).toHaveAttribute('aria-label', 'Add another reviewer name')
      })

      const reviewerRadio = screen.getByTestId('target-type-reviewer')
      await user.click(reviewerRadio)

      await waitFor(() => {
        expect(addButton).toHaveAttribute('aria-label', 'Add another recipient name')
      })
    })

    it('provides screen reader labels for delete buttons', async () => {
      const addButton = screen.getByTestId('add-subject-button')

      await user.click(addButton)

      await waitFor(() => {
        const deleteButton = screen.getByTestId('delete-additional-subject-field-1-button')
        expect(deleteButton).toHaveTextContent('Delete additional empty subject field')
      })
    })
  })

  describe('Error handling', () => {
    beforeEach(() => {
      mockExecuteQuery.mockResolvedValue({
        assignment: {
          assignedStudents: {
            nodes: mockStudents,
          },
        },
      })
      renderWithProviders()
    })

    it('clears errors on input change', async () => {
      const saveButton = screen.getByTestId('save-button')

      await user.click(saveButton)

      await waitFor(() => {
        expect(screen.getByText('Reviewer is required')).toBeInTheDocument()
      })

      const reviewerInput = screen.getByText('Reviewer Name').querySelector('input')
      if (reviewerInput) {
        await user.type(reviewerInput, 'Student 1')
        await user.click(screen.getByText('Student 1'))

        await waitFor(() => {
          expect(screen.queryByText('Reviewer is required')).not.toBeInTheDocument()
        })
      }
    })
  })
})
