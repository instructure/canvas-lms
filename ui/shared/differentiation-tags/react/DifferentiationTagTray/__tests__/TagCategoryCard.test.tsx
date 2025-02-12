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
import TagCategoryCard, {TagCategoryCardProps} from '../TagCategoryCard'
import {
  noTagsCategory,
  singleTagCategory,
  multipleTagsCategory,
} from '../../util/tagCategoryCardMocks'

describe('TagCategoryCard', () => {
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
})
