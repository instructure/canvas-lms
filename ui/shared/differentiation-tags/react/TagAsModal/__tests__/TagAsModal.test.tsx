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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import TagAsModal from '../TagAsModal'
import type {TagAsModalProps} from '../TagAsModal'
import {singleTagCategory, multipleTagsCategory} from '../../util/tagCategoryCardMocks'
import type {DifferentiationTagCategory} from '../../types'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(() => vi.fn()),
  showFlashSuccess: vi.fn(() => vi.fn()),
}))

import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const BULK_MANAGE_URL = '*/group_categories/bulk_manage_differentiation_tag'

// The API returns created items wrapped as {group: {...}}, matching BulkManageDiffTagResponse
const server = setupServer(
  http.post(BULK_MANAGE_URL, () =>
    HttpResponse.json({
      created: [{group: {id: 999, name: 'New Variant', members_count: 0}}],
      updated: [],
      deleted: [],
      group_category: {id: 10, name: 'New Tag Set'},
    }),
  ),
)

const singleTagCategoryTyped: DifferentiationTagCategory = singleTagCategory
const multipleTagsCategoryTyped: DifferentiationTagCategory = multipleTagsCategory

const defaultProps: TagAsModalProps = {
  isOpen: true,
  onClose: vi.fn(),
  onCreationSuccess: vi.fn(),
  categories: [],
  courseId: 1,
}

const renderComponent = (props: Partial<TagAsModalProps> = {}) =>
  render(
    <MockedQueryProvider>
      <TagAsModal {...defaultProps} {...props} />
    </MockedQueryProvider>,
  )

describe('TagAsModal', () => {
  const user = userEvent.setup({delay: 0})

  beforeAll(() => server.listen())
  afterAll(() => server.close())
  beforeEach(() => vi.clearAllMocks())
  afterEach(() => server.resetHandlers())

  describe('rendering', () => {
    it('renders the modal when isOpen is true', () => {
      renderComponent()
      expect(screen.getByText('Tag Students As')).toBeInTheDocument()
    })

    it('does not render when isOpen is false', () => {
      renderComponent({isOpen: false})
      expect(screen.queryByText('Tag Students As')).not.toBeInTheDocument()
    })

    it('renders all four radio options', () => {
      renderComponent()
      expect(screen.getByLabelText('Existing tag')).toBeInTheDocument()
      expect(screen.getByLabelText('New tag with variants')).toBeInTheDocument()
      expect(screen.getByLabelText('New variant of existing tag')).toBeInTheDocument()
      expect(screen.getByLabelText('New single tag')).toBeInTheDocument()
    })

    it('renders the info alert about tag visibility', () => {
      renderComponent()
      expect(screen.getByText('Tags are not visible to students.')).toBeInTheDocument()
    })
  })

  describe('radio option disabled states', () => {
    it('disables "Existing tag" when there are no categories', () => {
      renderComponent({categories: []})
      expect(screen.getByLabelText('Existing tag')).toBeDisabled()
    })

    it('enables "Existing tag" when categories exist', () => {
      renderComponent({categories: [singleTagCategoryTyped]})
      expect(screen.getByLabelText('Existing tag')).toBeEnabled()
    })

    it('disables "New variant of existing tag" when no categories exist', () => {
      renderComponent({categories: []})
      expect(screen.getByLabelText('New variant of existing tag')).toBeDisabled()
    })

    it('disables "New variant of existing tag" when only single tags exist', () => {
      renderComponent({categories: [singleTagCategoryTyped]})
      expect(screen.getByLabelText('New variant of existing tag')).toBeDisabled()
    })

    it('enables "New variant of existing tag" when multi-variant categories exist', () => {
      renderComponent({categories: [multipleTagsCategoryTyped]})
      expect(screen.getByLabelText('New variant of existing tag')).toBeEnabled()
    })
  })

  describe('default selected option', () => {
    it('defaults to "Existing tag" when categories exist', () => {
      renderComponent({categories: [singleTagCategoryTyped]})
      expect(screen.getByLabelText('Existing tag')).toBeChecked()
    })

    it('defaults to "New tag with variants" when no categories exist', () => {
      renderComponent({categories: []})
      expect(screen.getByLabelText('New tag with variants')).toBeChecked()
    })
  })

  describe('"Existing tag" option', () => {
    const categories = [singleTagCategoryTyped, multipleTagsCategoryTyped]

    it('shows a tag selector and no other form inputs', () => {
      renderComponent({categories})
      expect(screen.getByTestId('existing-tag-selector')).toBeInTheDocument()
      expect(screen.queryByTestId('variant-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('tag-set-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('existing-tag-set-selector')).not.toBeInTheDocument()
      expect(screen.queryByTestId('new-variant-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('tag-name-input')).not.toBeInTheDocument()
    })

    it('renders single tags as flat options (no group header)', () => {
      renderComponent({categories: [singleTagCategoryTyped]})
      // Single tag name appears directly as an option label
      expect(screen.getByTitle('Honors')).toBeInTheDocument()
    })

    it('renders multi-variant categories as grouped options', async () => {
      renderComponent({categories: [multipleTagsCategoryTyped]})
      await user.click(screen.getByTestId('existing-tag-selector'))
      // Group label for the category
      expect(screen.getByText('Reading Groups')).toBeInTheDocument()
      // Individual variants as options
      expect(await screen.findByRole('option', {name: 'Variant A'})).toBeInTheDocument()
      expect(await screen.findByRole('option', {name: 'Variant B'})).toBeInTheDocument()
    })

    it('calls onCreationSuccess with a single tag group ID without an API call', async () => {
      let apiCalled = false
      server.use(
        http.post(BULK_MANAGE_URL, () => {
          apiCalled = true
          return HttpResponse.json({})
        }),
      )

      renderComponent({categories: [singleTagCategoryTyped]})
      await user.click(screen.getByTestId('existing-tag-selector'))
      await user.click(await screen.findByRole('option', {name: 'Honors'}))
      await user.click(screen.getByTestId('submit-button'))

      await waitFor(() => {
        expect(defaultProps.onCreationSuccess).toHaveBeenCalledWith(101) // group id
        expect(apiCalled).toBe(false)
      })
    })

    it('calls onCreationSuccess with a multi-variant group ID without an API call', async () => {
      let apiCalled = false
      server.use(
        http.post(BULK_MANAGE_URL, () => {
          apiCalled = true
          return HttpResponse.json({})
        }),
      )

      renderComponent({categories: [multipleTagsCategoryTyped]})
      await user.click(screen.getByTestId('existing-tag-selector'))
      await user.click(await screen.findByRole('option', {name: 'Variant A'}))
      await user.click(screen.getByTestId('submit-button'))

      await waitFor(() => {
        expect(defaultProps.onCreationSuccess).toHaveBeenCalledWith(201) // Variant A group id
        expect(apiCalled).toBe(false)
      })
    })

    it('shows validation error when no tag is selected', async () => {
      renderComponent({categories})
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.getByText('Please select a tag')).toBeInTheDocument()
      })
    })
  })

  describe('"New tag with variants" option', () => {
    it('shows variant name and tag set name inputs and no other form inputs', async () => {
      renderComponent({categories: []})
      // Already selected by default when no categories
      expect(screen.getByTestId('variant-name-input')).toBeInTheDocument()
      expect(screen.getByTestId('tag-set-name-input')).toBeInTheDocument()
      expect(screen.queryByTestId('existing-tag-selector')).not.toBeInTheDocument()
      expect(screen.queryByTestId('existing-tag-set-selector')).not.toBeInTheDocument()
      expect(screen.queryByTestId('new-variant-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('tag-name-input')).not.toBeInTheDocument()
    })

    it('shows validation errors when fields are empty', async () => {
      renderComponent({categories: []})
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.getByText('Variant name is required')).toBeInTheDocument()
        expect(screen.getByText('Tag Set Name is required')).toBeInTheDocument()
      })
    })

    it('clears only the variant name error when user types in that field', async () => {
      renderComponent({categories: []})
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.getByText('Variant name is required')).toBeInTheDocument()
        expect(screen.getByText('Tag Set Name is required')).toBeInTheDocument()
      })

      await user.type(screen.getByTestId('variant-name-input'), 'x')

      expect(screen.queryByText('Variant name is required')).not.toBeInTheDocument()
      expect(screen.getByText('Tag Set Name is required')).toBeInTheDocument()
    })

    it('calls the API with correct payload and invokes onCreationSuccess with created group ID', async () => {
      let requestBody: any
      server.use(
        http.post(BULK_MANAGE_URL, async ({request}) => {
          requestBody = await request.json()
          return HttpResponse.json({
            created: [{group: {id: 999, name: 'Level 1', members_count: 0}}],
            updated: [],
            deleted: [],
            group_category: {id: 10, name: 'Reading Levels'},
          })
        }),
      )

      renderComponent({categories: []})
      await user.type(screen.getByTestId('variant-name-input'), 'Level 1')
      await user.type(screen.getByTestId('tag-set-name-input'), 'Reading Levels')
      await user.click(screen.getByTestId('submit-button'))

      await waitFor(() => {
        expect(requestBody.group_category.name).toBe('Reading Levels')
        expect(requestBody.group_category.id).toBeUndefined()
        expect(requestBody.operations.create).toEqual([{name: 'Level 1'}])
        expect(defaultProps.onCreationSuccess).toHaveBeenCalledWith(999)
      })
    })

    it('shows a flash error and does not call onCreationSuccess when the API fails', async () => {
      server.use(
        http.post(BULK_MANAGE_URL, () =>
          HttpResponse.json({errors: 'Server error'}, {status: 500}),
        ),
      )

      renderComponent({categories: []})
      await user.type(screen.getByTestId('variant-name-input'), 'x')
      await user.type(screen.getByTestId('tag-set-name-input'), 'x')
      await user.click(screen.getByTestId('submit-button'))

      await waitFor(() => {
        expect(showFlashError).toHaveBeenCalled()
        expect(defaultProps.onCreationSuccess).not.toHaveBeenCalled()
      })
    })
  })

  describe('"New variant of existing tag" option', () => {
    const categories = [multipleTagsCategoryTyped]

    it('shows tag set selector and variant name input and no other form inputs', async () => {
      renderComponent({categories})
      await user.click(screen.getByLabelText('New variant of existing tag'))
      expect(screen.getByTestId('existing-tag-set-selector')).toBeInTheDocument()
      expect(screen.getByTestId('new-variant-name-input')).toBeInTheDocument()
      expect(screen.queryByTestId('existing-tag-selector')).not.toBeInTheDocument()
      expect(screen.queryByTestId('variant-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('tag-set-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('tag-name-input')).not.toBeInTheDocument()
    })

    it('lists only multi-variant categories in the tag set selector', async () => {
      renderComponent({categories: [singleTagCategoryTyped, multipleTagsCategoryTyped]})
      await user.click(screen.getByLabelText('New variant of existing tag'))
      await user.click(screen.getByTestId('existing-tag-set-selector'))
      // Multi-variant category should appear
      expect(screen.getByTitle('Reading Groups')).toBeInTheDocument()
      // Single tag category should NOT appear
      expect(screen.queryByTitle('Honors')).not.toBeInTheDocument()
    })

    it('auto-selects the first tag set when switching to this option', async () => {
      renderComponent({categories})
      await user.click(screen.getByLabelText('New variant of existing tag'))
      // The first multi-variant category should already be shown as selected
      expect(screen.getByTitle('Reading Groups')).toBeInTheDocument()
    })

    it('shows only variant name error when tag set is pre-selected and variant name is empty', async () => {
      renderComponent({categories})
      await user.click(screen.getByLabelText('New variant of existing tag'))
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.queryByText('Please select a tag set')).not.toBeInTheDocument()
        expect(screen.getByText('Variant name is required')).toBeInTheDocument()
      })
    })

    it('calls the API with correct groupCategoryId (no name) and invokes onCreationSuccess', async () => {
      let requestBody: any
      server.use(
        http.post(BULK_MANAGE_URL, async ({request}) => {
          requestBody = await request.json()
          return HttpResponse.json({
            created: [{group: {id: 999, name: 'Variant D', members_count: 0}}],
            updated: [],
            deleted: [],
            group_category: {id: 3, name: 'Reading Groups'},
          })
        }),
      )

      renderComponent({categories})
      await user.click(screen.getByLabelText('New variant of existing tag'))
      // Tag set is pre-selected; just type the variant name and submit
      await user.type(screen.getByTestId('new-variant-name-input'), 'Variant D')
      await user.click(screen.getByTestId('submit-button'))

      await waitFor(() => {
        expect(requestBody.group_category.id).toBe(3)
        expect(requestBody.group_category.name).toBeUndefined()
        expect(requestBody.operations.create).toEqual([{name: 'Variant D'}])
        expect(defaultProps.onCreationSuccess).toHaveBeenCalledWith(999)
      })
    })
  })

  describe('"New single tag" option', () => {
    it('shows a tag name input and no other form inputs', async () => {
      renderComponent({categories: []})
      await user.click(screen.getByLabelText('New single tag'))
      expect(screen.getByTestId('tag-name-input')).toBeInTheDocument()
      expect(screen.queryByTestId('existing-tag-selector')).not.toBeInTheDocument()
      expect(screen.queryByTestId('variant-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('tag-set-name-input')).not.toBeInTheDocument()
      expect(screen.queryByTestId('existing-tag-set-selector')).not.toBeInTheDocument()
      expect(screen.queryByTestId('new-variant-name-input')).not.toBeInTheDocument()
    })

    it('shows validation error when tag name is empty', async () => {
      renderComponent({categories: []})
      await user.click(screen.getByLabelText('New single tag'))
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.getByText('Tag name is required')).toBeInTheDocument()
      })
    })

    it('calls the API with category name equal to tag name and invokes onCreationSuccess', async () => {
      let requestBody: any
      server.use(
        http.post(BULK_MANAGE_URL, async ({request}) => {
          requestBody = await request.json()
          return HttpResponse.json({
            created: [{group: {id: 999, name: 'Honors', members_count: 0}}],
            updated: [],
            deleted: [],
            group_category: {id: 10, name: 'Honors'},
          })
        }),
      )

      renderComponent({categories: []})
      await user.click(screen.getByLabelText('New single tag'))
      await user.type(screen.getByTestId('tag-name-input'), 'Honors')
      await user.click(screen.getByTestId('submit-button'))

      await waitFor(() => {
        expect(requestBody.group_category.name).toBe('Honors')
        expect(requestBody.operations.create).toEqual([{name: 'Honors'}])
        expect(defaultProps.onCreationSuccess).toHaveBeenCalledWith(999)
      })
    })
  })

  describe('switching radio options', () => {
    it('resets inputs when switching from "New tag with variants" to another option', async () => {
      renderComponent({categories: []})
      await user.type(screen.getByTestId('variant-name-input'), 'x')
      await user.type(screen.getByTestId('tag-set-name-input'), 'x')

      await user.click(screen.getByLabelText('New single tag'))
      await user.click(screen.getByLabelText('New tag with variants'))

      expect(screen.getByTestId('variant-name-input')).toHaveValue('')
      expect(screen.getByTestId('tag-set-name-input')).toHaveValue('')
    })

    it('clears validation errors when switching options', async () => {
      renderComponent({categories: []})
      await user.click(screen.getByTestId('submit-button'))
      await waitFor(() => {
        expect(screen.getByText('Variant name is required')).toBeInTheDocument()
      })

      await user.click(screen.getByLabelText('New single tag'))
      expect(screen.queryByText('Variant name is required')).not.toBeInTheDocument()
    })
  })

  describe('form close and cancel', () => {
    it('calls onClose when the close button is clicked', async () => {
      renderComponent()
      await user.click(screen.getByRole('button', {name: 'Close', hidden: true}))
      expect(defaultProps.onClose).toHaveBeenCalled()
    })

    it('calls onClose when the cancel button is clicked', async () => {
      renderComponent()
      await user.click(screen.getByTestId('cancel-button'))
      expect(defaultProps.onClose).toHaveBeenCalled()
    })

    it('resets form state when closed', async () => {
      renderComponent({categories: []})
      await user.type(screen.getByTestId('variant-name-input'), 'x')
      await user.click(screen.getByTestId('cancel-button'))
      // Re-render to simulate reopening
      renderComponent({categories: []})
      expect(screen.getAllByTestId('variant-name-input')[0]).toHaveValue('')
    })
  })

  describe('submit button state', () => {
    it('disables the submit button and shows "Saving..." during submission', async () => {
      // Delay the server response so we can observe the in-flight state
      server.use(
        http.post(BULK_MANAGE_URL, async () => {
          await new Promise(resolve => setTimeout(resolve, 50))
          return HttpResponse.json({
            created: [{group: {id: 999, name: 'Honors', members_count: 0}}],
            updated: [],
            deleted: [],
            group_category: {id: 10, name: 'Honors'},
          })
        }),
      )

      renderComponent({categories: []})
      await user.click(screen.getByLabelText('New single tag'))
      await user.type(screen.getByTestId('tag-name-input'), 'x')
      await user.click(screen.getByTestId('submit-button'))

      expect(screen.getByTestId('submit-button')).toBeDisabled()
      expect(screen.getByText('Saving...')).toBeInTheDocument()

      await waitFor(() => {
        expect(screen.queryByText('Saving...')).not.toBeInTheDocument()
      })
    })
  })
})
