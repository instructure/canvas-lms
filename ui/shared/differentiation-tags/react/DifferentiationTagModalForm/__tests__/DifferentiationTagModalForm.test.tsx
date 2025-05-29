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
import DifferentiationTagModalForm from '../DifferentiationTagModalForm'
import type {DifferentiationTagModalFormProps} from '../DifferentiationTagModalForm'
import '@testing-library/jest-dom'
import {CREATE_MODE, EDIT_MODE} from '../../util/constants'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {multipleTagsCategory, singleTagCategory} from '../../util/tagCategoryCardMocks'

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(() =>
    Promise.resolve({
      response: {ok: true},
      json: {
        created: [],
        updated: [],
        deleted: [],
        group_category: {id: 1, name: 'Mock Tag Set'},
      },
    }),
  ),
}))

describe('DifferentiationTagModalForm', () => {
  const user = userEvent.setup({delay: 0})

  const onCloseMock = jest.fn()
  const mockTagSet = multipleTagsCategory

  const renderComponent = (props: Partial<DifferentiationTagModalFormProps> = {}) => {
    const defaultProps = {
      isOpen: true,
      mode: CREATE_MODE,
      onClose: onCloseMock,
      courseId: 1,
      ...props,
    } as DifferentiationTagModalFormProps

    render(
      <MockedQueryProvider>
        <DifferentiationTagModalForm {...defaultProps} />
      </MockedQueryProvider>,
    )
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the modal when isOpen is true', () => {
    renderComponent()
    expect(screen.getByText('Create Tag')).toBeInTheDocument()
  })

  it('does not render when isOpen is false', () => {
    renderComponent({isOpen: false})
    expect(screen.queryByText('Create Tag')).not.toBeInTheDocument()
  })

  describe('create mode UI', () => {
    it('shows create title and save button', () => {
      renderComponent({mode: CREATE_MODE})
      expect(screen.getByText('Create Tag')).toBeInTheDocument()
      expect(screen.getByText('Save')).toBeInTheDocument()
    })

    it('displays tag set selector', () => {
      renderComponent({mode: CREATE_MODE})
      // Assumes the select component renders a label "Tag Set"
      expect(screen.getByText('Tag Set')).toBeInTheDocument()
    })

    it('does not show variant radio buttons', () => {
      renderComponent({mode: CREATE_MODE})
      expect(screen.queryByText('Single Tag')).not.toBeInTheDocument()
      expect(screen.queryByText('Multiple Tags')).not.toBeInTheDocument()
    })

    it('renders modal content correctly', async () => {
      renderComponent({mode: CREATE_MODE})

      const input = screen.getByTestId('tag-set-selector')
      expect(input).toBeInTheDocument()

      expect(screen.getByTitle('Add as a single tag')).toBeInTheDocument()
      expect(screen.queryByLabelText('Tag Set Name')).not.toBeInTheDocument()

      const addAnotherTagButton = screen.getByLabelText('Add another tag')
      await user.click(addAnotherTagButton)

      expect(screen.getByTitle('Create a new Tag Set')).toBeInTheDocument()
      expect(screen.getByText('Tag Set Name')).toBeInTheDocument()
    })
    it('focuses the empty Tag name input when saving with an empty Tag name', async () => {
      renderComponent({mode: CREATE_MODE})
      const tagInput = screen.getByLabelText(/Tag Name/i)
      await user.clear(tagInput)
      const saveButton = screen.getByLabelText('Save')
      await user.click(saveButton)
      await waitFor(() => {
        expect(screen.getByText('Tag Name is required')).toBeInTheDocument()
      })
      expect(document.activeElement).toBe(tagInput)
    })

    it('puts focus on the newly added tag input field', async () => {
      renderComponent({mode: CREATE_MODE})

      const initialInputs = screen.getAllByLabelText(/Tag Name/i)
      await user.click(screen.getByLabelText('Add another tag'))
      await user.click(screen.getByLabelText('Add another tag'))
      const newInputs = screen.getAllByLabelText(/Tag Name/i)

      expect(newInputs).toHaveLength(initialInputs.length + 2)
      expect(newInputs[newInputs.length - 1]).toHaveFocus()
    })

    it('updates category to "Add as a single tag" when removing a tag leaves one input (create mode)', async () => {
      renderComponent({mode: CREATE_MODE})

      // Initially one tag → option is "Add as a single tag"
      expect(screen.getByTitle('Add as a single tag')).toBeInTheDocument()

      // Add another tag so that the category becomes "Create a new Tag Set".
      const addAnotherTagButton = screen.getByLabelText('Add another tag')
      await user.click(addAnotherTagButton)
      expect(screen.getByTitle('Create a new Tag Set')).toBeInTheDocument()

      // Remove one tag.
      const removeButtons = screen.getAllByRole('button', {name: /remove tag/i, hidden: true})
      await user.click(removeButtons[0])

      // With one tag left, the option should revert to "Add as a single tag".
      expect(screen.getByTitle('Add as a single tag')).toBeInTheDocument()
    })

    it('moves focus to previous row remove button when a tag input row is deleted', async () => {
      renderComponent({mode: CREATE_MODE})

      await user.click(screen.getByLabelText('Add another tag'))
      await user.click(screen.getByLabelText('Add another tag'))

      // Get all remove buttons in reverse order as we want to delete the last one
      const removeButtons = screen
        .getAllByRole('button', {name: /remove tag/i, hidden: true})
        .reverse()
      await user.click(removeButtons[0])

      // Verify that focus has moved to the previous row's remove button
      expect(removeButtons[1]).toHaveFocus()
    })

    it('moves focus to the first tag input row if the second tag input row is deleted', async () => {
      renderComponent({mode: CREATE_MODE})

      await user.click(screen.getByLabelText('Add another tag'))
      await user.click(screen.getByLabelText('Add another tag'))

      const removeButtons = screen.getAllByRole('button', {name: /remove tag/i, hidden: true})
      // Remove the second tag input row (first one is the default one)
      await user.click(removeButtons[0])

      // Verify that focus has moved to the first tag input row
      expect(screen.getAllByLabelText(/Tag Name/i)[0]).toHaveFocus()
    })
  })

  describe('edit mode UI', () => {
    it('shows edit title and save button', () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: mockTagSet})
      expect(screen.getByText('Edit Tag')).toBeInTheDocument()
      expect(screen.getByText('Save')).toBeInTheDocument()
    })

    it('displays variant radio buttons', () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: mockTagSet})
      // Verify that radio button labels appear.
      expect(screen.getByText('Single Tag')).toBeInTheDocument()
      expect(screen.getByText('Multiple Tags')).toBeInTheDocument()
    })

    it('renders tag inputs for each group', () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: mockTagSet})
      expect(screen.getByDisplayValue('Variant A')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Variant B')).toBeInTheDocument()
    })

    it('does not render the "+ Add another tag" button when in edit single mode', () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: singleTagCategory})
      expect(screen.queryByText('Add another tag')).not.toBeInTheDocument()
    })

    it('renders the "Add another tag" button when in edit multi mode', () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: mockTagSet})
      expect(screen.getByText('+ Add another tag')).toBeInTheDocument()
    })

    it('populates tag set name and tag variants correctly in edit view (multi mode)', async () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: multipleTagsCategory})
      const multipleTagRadio = screen.getByLabelText('Multiple Tags')
      expect(multipleTagRadio).toBeChecked()
      const tagSetNameInput = screen.getByTestId('tag-set-name')
      expect(tagSetNameInput).toHaveValue('Reading Groups')
      expect(screen.getByDisplayValue('Variant A')).toBeInTheDocument()
      expect(screen.getByDisplayValue('Variant B')).toBeInTheDocument()
    })

    it("doesn't switch to single tag mode when removing a tag in edit mode with multiple tags", async () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: mockTagSet})
      const multipleTagRadio = screen.getByLabelText('Multiple Tags')
      expect(multipleTagRadio).toBeChecked()
      // Remove one tag.
      const removeButtons = screen.getAllByRole('button', {name: /remove Variant A/i, hidden: true})
      await user.click(removeButtons[0])
      // The radio button for "Multiple Tags" should remain checked.
      expect(multipleTagRadio).toBeChecked()
      // And the Tag Set Name input should still be visible.
      expect(screen.getByTestId('tag-set-name')).toBeInTheDocument()
    })

    it('focuses on the first element on error on edit mode', async () => {
      renderComponent({mode: EDIT_MODE, differentiationTagSet: multipleTagsCategory})
      const tagSetNameInput = screen.getByTestId('tag-set-name')
      await user.clear(tagSetNameInput)
      const tagInput = screen.getByDisplayValue('Variant A')
      await user.clear(tagInput)
      const saveButton = screen.getByLabelText('Save')
      await user.click(saveButton)
      await waitFor(() => {
        expect(screen.getByText('Tag Set Name is required')).toBeInTheDocument()
        expect(screen.getByText('Tag Name is required')).toBeInTheDocument()
      })
      expect(document.activeElement).toBe(tagSetNameInput)
    })
  })

  it('displays info alert about tag visibility', () => {
    renderComponent()
    expect(screen.getByText(/Tags are not visible to students/)).toBeInTheDocument()
  })

  it('calls onClose when clicking the close button', async () => {
    renderComponent()
    await user.click(screen.getByRole('button', {name: 'Close', hidden: true}))
    expect(onCloseMock).toHaveBeenCalled()
  })

  it('calls onClose when clicking the cancel button', async () => {
    renderComponent()
    await user.click(screen.getByTestId('cancel-button'))
    expect(onCloseMock).toHaveBeenCalled()
  })

  it('persists edited state when switching between single and multiple tag modes fast', async () => {
    renderComponent({
      mode: EDIT_MODE,
      differentiationTagSet: mockTagSet,
    })

    // Edit both tag inputs
    const tag1Input = screen.getByDisplayValue('Variant A')
    const tag2Input = screen.getByDisplayValue('Variant B')

    await user.clear(tag1Input)
    await user.paste('Updated Group 1')

    await user.clear(tag2Input)
    await user.paste('Updated Group 2')

    // Batch mode switches in a single event queue
    await user.click(screen.getByText('Single Tag'))
    await user.click(screen.getByText('Multiple Tags'))

    expect(screen.getByDisplayValue('Updated Group 1')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Updated Group 2')).toBeInTheDocument()
  })

  it('shows error when tag name is empty on submission in create mode', async () => {
    renderComponent({mode: CREATE_MODE})
    const saveButton = screen.getByLabelText('Save')
    await user.click(saveButton)

    await waitFor(() => {
      expect(screen.getByText('Tag Name is required')).toBeInTheDocument()
    })
  })

  it('shows error when tag set name is empty in create mode with multiple tags', async () => {
    renderComponent({mode: CREATE_MODE})

    // Switch to multi tag mode.
    const addAnotherTagButton = screen.getByLabelText('Add another tag')
    await user.click(addAnotherTagButton)

    // Fill the tag input with a valid value to avoid a tag name error.
    const tagInput = screen.getAllByTestId('tag-name-input')[0]
    await user.clear(tagInput)
    await user.type(tagInput, 'Valid Tag')

    // Leave the Tag Set Name input empty and click save.
    const saveButton = screen.getByLabelText('Save')
    await user.click(saveButton)

    await waitFor(() => {
      expect(screen.getByText('Tag Set Name is required')).toBeInTheDocument()
    })
  })

  it('successfully submits the form in create mode with valid input', async () => {
    renderComponent({mode: CREATE_MODE})

    const tagInput = screen.getByLabelText(/Tag Name/i)
    await user.clear(tagInput)
    await user.type(tagInput, 'Valid Tag')

    const saveButton = screen.getByLabelText('Save')
    await user.click(saveButton)

    await waitFor(() => {
      expect(onCloseMock).toHaveBeenCalled()
    })
  })

  it('shows error when tag set name is empty in edit mode with multi tag mode', async () => {
    renderComponent({mode: EDIT_MODE, differentiationTagSet: multipleTagsCategory})

    // Clear the tag set name (initially populated in edit mode) to trigger the error.
    const tagSetNameInput = screen.getByTestId('tag-set-name')
    await user.clear(tagSetNameInput)

    const saveButton = screen.getByLabelText('Save')
    await user.click(saveButton)
    await waitFor(() => {
      expect(screen.getByText('Tag Set Name is required')).toBeInTheDocument()
    })
  })

  it('resets form state on modal close', async () => {
    // Open the modal in create mode and fill in a tag name.
    renderComponent({mode: CREATE_MODE})
    const tagInput = screen.getAllByLabelText(/Tag Name/i)[0]
    await user.clear(tagInput)
    await user.type(tagInput, 'Temporary Tag')

    // Close the modal using the cancel button.
    const cancelButton = screen.getByTestId('cancel-button')
    await user.click(cancelButton)
    expect(onCloseMock).toHaveBeenCalled()

    // Re-open the modal (a new instance will have initial state).
    renderComponent({mode: CREATE_MODE})
    const newTagInput = screen.getAllByLabelText(/Tag Name/i)[0]
    expect(newTagInput).toHaveValue('')
  })

  it('clears tag name error message when user types valid input', async () => {
    renderComponent({mode: CREATE_MODE})

    // Trigger the error by clicking save without filling the tag name.
    const saveButton = screen.getByLabelText('Save')
    await user.click(saveButton)

    await waitFor(() => {
      expect(screen.getByText('Tag Name is required')).toBeInTheDocument()
    })

    // Now type a valid tag name.
    const tagInput = screen.getByLabelText(/Tag Name/i)
    await user.type(tagInput, 'Valid Tag')
    expect(screen.queryByText('Tag Name is required')).not.toBeInTheDocument()
  })
})
