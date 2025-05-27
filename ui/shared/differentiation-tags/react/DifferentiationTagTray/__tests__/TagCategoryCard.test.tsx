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
import TagCategoryCard, {TagCategoryCardProps} from '../TagCategoryCard'
import {
  noTagsCategory,
  singleTagCategory,
  multipleTagsCategory,
  tagSetWithOneTag,
} from '../../util/tagCategoryCardMocks'
import {useDeleteDifferentiationTagCategory} from '../../hooks/useDeleteDifferentiationTagCategory'

jest.mock('../../hooks/useDeleteDifferentiationTagCategory')

describe('TagCategoryCard', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    // Set a default mock return value so that deleteMutation is defined in all tests.
    ;(useDeleteDifferentiationTagCategory as jest.Mock).mockReturnValue({
      mutate: jest.fn(),
      isLoading: false,
    })
  })

  const renderComponent = (props?: Partial<TagCategoryCardProps>) => {
    const defaultProps: TagCategoryCardProps = {
      category: noTagsCategory,
      onEditCategory: jest.fn(),
    }
    return render(<TagCategoryCard {...defaultProps} {...props} />)
  }

  it('renders the category name', () => {
    renderComponent({category: noTagsCategory})
    expect(screen.getByText(noTagsCategory.name)).toBeInTheDocument()
  })

  it('displays a "no groups" message and an add variant link when groups are empty', () => {
    renderComponent({category: noTagsCategory})
    expect(screen.getByText('No tags in tag set')).toBeInTheDocument()
    expect(screen.getByText('+ Add a variant')).toBeInTheDocument()
  })

  it('displays information for a single group', () => {
    renderComponent({category: singleTagCategory})
    expect(screen.getByText(singleTagCategory.name)).toBeInTheDocument()
    expect(screen.getByText('15 students')).toBeInTheDocument()
    expect(screen.getByText('Single tag')).toBeInTheDocument()
  })

  it('displays information for a single group', () => {
    renderComponent({category: tagSetWithOneTag})
    expect(screen.getByText(tagSetWithOneTag.name)).toBeInTheDocument()
    expect(screen.getByText('15 students')).toBeInTheDocument()
    expect(screen.queryByText('Single tag')).not.toBeInTheDocument()
  })

  it('displays information for multiple groups', () => {
    renderComponent({category: multipleTagsCategory})
    expect(screen.getByText(multipleTagsCategory.name)).toBeInTheDocument()
    expect(screen.getByText('10 students')).toBeInTheDocument()
    expect(screen.getByText('20 students')).toBeInTheDocument()
    expect(screen.getByText('30 students')).toBeInTheDocument()
    expect(screen.getByText('+ Add a variant')).toBeInTheDocument()
  })

  it('calls onEditCategory when the edit icon button is clicked', async () => {
    const onEditCategoryMock = jest.fn()
    const editableCategory = {...noTagsCategory, id: 4, name: 'Editable Category'}

    renderComponent({category: editableCategory, onEditCategory: onEditCategoryMock})

    const editTextElement = screen.getByText('Edit')
    const editButton = editTextElement.closest('button')
    expect(editButton).toBeTruthy()

    await userEvent.click(editButton!)
    expect(onEditCategoryMock).toHaveBeenCalledWith(4)
  })

  it('calls onEditCategory when the "+ Add a variant" link is clicked (empty groups)', async () => {
    const onEditCategoryMock = jest.fn()

    const emptyGroupsCategory = {...noTagsCategory, id: 5, name: 'Empty Groups Category'}
    renderComponent({category: emptyGroupsCategory, onEditCategory: onEditCategoryMock})

    const addVariantLink = screen.getByText('+ Add a variant')
    await userEvent.click(addVariantLink)
    expect(onEditCategoryMock).toHaveBeenCalledWith(5)
  })

  it('calls onEditCategory when the "+ Add a variant" link is clicked (multiple groups)', async () => {
    const onEditCategoryMock = jest.fn()

    const multiGroupsCategory = {...multipleTagsCategory, id: 6, name: 'Multi Groups Category'}
    renderComponent({category: multiGroupsCategory, onEditCategory: onEditCategoryMock})

    const addVariantLink = screen.getByText('+ Add a variant')
    await userEvent.click(addVariantLink)
    expect(onEditCategoryMock).toHaveBeenCalledWith(6)
  })

  describe('Delete functionality', () => {
    it('opens the delete warning modal when delete button is clicked', async () => {
      renderComponent()
      const deleteButton = screen.getByText(`Delete ${noTagsCategory.name}`).closest('button')
      if (!deleteButton) throw new Error('Delete button not found')
      await userEvent.click(deleteButton)
      expect(screen.getByText('Delete Tag')).toBeInTheDocument()
    })

    it('displays a loading state in the modal when deletion is in progress', async () => {
      ;(useDeleteDifferentiationTagCategory as jest.Mock).mockReturnValue({
        mutate: jest.fn(),
        isPending: true,
      })
      renderComponent()
      const deleteButton = screen.getByText(`Delete ${noTagsCategory.name}`).closest('button')
      if (!deleteButton) throw new Error('Delete button not found')
      await userEvent.click(deleteButton)
      // The confirm button should now display "Deleting..." and be disabled.
      const confirmButton = screen.getByText('Deleting...').closest('button')
      if (!confirmButton) throw new Error('Confirm button not found')
      expect(confirmButton).toBeDisabled()
    })

    it('calls the delete mutation and closes the modal on successful deletion', async () => {
      const mockMutate = jest.fn((_, {onSuccess}) => {
        onSuccess && onSuccess()
      })
      ;(useDeleteDifferentiationTagCategory as jest.Mock).mockReturnValue({
        mutate: mockMutate,
        isLoading: false,
      })
      renderComponent()
      const deleteButton = screen.getByText(`Delete ${noTagsCategory.name}`).closest('button')
      if (!deleteButton) throw new Error('Delete button not found')
      await userEvent.click(deleteButton)
      const confirmButton = screen.getByText('Confirm').closest('button')
      if (!confirmButton) throw new Error('Confirm button not found')
      await userEvent.click(confirmButton)
      await waitFor(() => {
        expect(screen.queryByText('Delete Tag')).not.toBeInTheDocument()
      })
      expect(mockMutate).toHaveBeenCalled()
    })

    it('displays an error message when deletion fails', async () => {
      const mockMutate = jest.fn((_, {onError}) => {
        onError && onError(new Error('Deletion failed'))
      })
      ;(useDeleteDifferentiationTagCategory as jest.Mock).mockReturnValue({
        mutate: mockMutate,
        isLoading: false,
      })
      renderComponent()
      const deleteButton = screen.getByText(`Delete ${noTagsCategory.name}`).closest('button')
      if (!deleteButton) throw new Error('Delete button not found')
      await userEvent.click(deleteButton)
      const confirmButton = screen.getByText('Confirm').closest('button')
      if (!confirmButton) throw new Error('Confirm button not found')
      await userEvent.click(confirmButton)
      expect(screen.getByText('Deletion failed')).toBeInTheDocument()
      // The modal should remain open for the user to retry.
      expect(screen.getByText('Delete Tag')).toBeInTheDocument()
    })
  })

  it('has the proper role and aria-label attributes', () => {
    const {container} = renderComponent({category: noTagsCategory})
    const card = container.querySelector('span[role="group"]')
    expect(card).toHaveAttribute('aria-label', noTagsCategory.name)
  })
})
