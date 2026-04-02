// @vitest-environment jsdom
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
import {render, fireEvent, within, waitFor} from '@testing-library/react'
import NavMenuLinksSettings from '../NavMenuLinksSettings'
import {useNavMenuLinksStore} from '../useNavMenuLinksStore'
import {confirmDanger} from '@canvas/instui-bindings/react/Confirm'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock the store
vi.mock('../useNavMenuLinksStore')

// Mock confirmDanger
vi.mock('@canvas/instui-bindings/react/Confirm', () => ({
  confirmDanger: vi.fn(),
}))

// Mock the AddLinkModal
vi.mock('@canvas/nav-menu-links/react/components/AddLinkModal', () => ({
  AddLinkModal: ({onDismiss, onAdd}: any) => (
    <div data-testid="add-link-modal">
      <button
        onClick={() => {
          onAdd({url: 'https://example.com/test', label: 'Test Link'})
          onDismiss()
        }}
      >
        Add Test Link
      </button>
      <button onClick={onDismiss}>Cancel</button>
    </div>
  ),
}))

describe('NavMenuLinksSettings', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    fakeENV.setup({
      PERMISSIONS: {
        manage_nav_menu_links: true,
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders empty list when no links exist', () => {
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [],
      appendLink: vi.fn(),
      deleteLink: vi.fn(),
    })

    const {container} = render(<NavMenuLinksSettings />)

    const list = container.querySelector('.ic-Sortable-list')
    expect(list).toBeInTheDocument()
    expect(list?.children.length).toBe(0)
  })

  it('opens and closes add link modal', () => {
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [],
      appendLink: vi.fn(),
      deleteLink: vi.fn(),
    })

    const {getByText, getByTestId, queryByTestId} = render(<NavMenuLinksSettings />)

    expect(queryByTestId('add-link-modal')).not.toBeInTheDocument()

    fireEvent.click(getByText('Add a Link'))
    expect(getByTestId('add-link-modal')).toBeInTheDocument()

    fireEvent.click(getByText('Cancel'))
    expect(queryByTestId('add-link-modal')).not.toBeInTheDocument()
  })

  it('calls appendLink when a new link is added', () => {
    const mockAppendLink = vi.fn()
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [],
      appendLink: mockAppendLink,
      deleteLink: vi.fn(),
    })

    const {getByText} = render(<NavMenuLinksSettings />)

    fireEvent.click(getByText('Add a Link'))
    fireEvent.click(getByText('Add Test Link'))

    expect(mockAppendLink).toHaveBeenCalledWith({
      url: 'https://example.com/test',
      label: 'Test Link',
    })
  })

  it('shows confirmation dialog when delete is clicked', async () => {
    vi.mocked(confirmDanger).mockResolvedValue(false)
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [
        {
          type: 'existing',
          id: '1',
          url: 'https://example.com',
          label: 'Link to Delete',
          placements: {course_nav: true, account_nav: false, user_nav: false},
        },
      ],
      appendLink: vi.fn(),
      deleteLink: vi.fn(),
    })

    const {getByRole} = render(<NavMenuLinksSettings />)

    fireEvent.click(getByRole('button', {name: 'Delete Link to Delete'}))

    await waitFor(() =>
      expect(confirmDanger).toHaveBeenCalledWith(
        expect.objectContaining({
          title: 'Delete Custom Link',
          confirmButtonLabel: 'Delete',
        }),
      ),
    )
  })

  it('calls deleteLink when confirmed', async () => {
    const mockDeleteLink = vi.fn()
    vi.mocked(confirmDanger).mockResolvedValue(true)
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [
        {
          type: 'existing',
          id: '1',
          url: 'https://example.com',
          label: 'Link to Delete',
          placements: {course_nav: true, account_nav: false, user_nav: false},
        },
      ],
      appendLink: vi.fn(),
      deleteLink: mockDeleteLink,
    })

    const {getByRole} = render(<NavMenuLinksSettings />)

    fireEvent.click(getByRole('button', {name: 'Delete Link to Delete'}))

    await waitFor(() => expect(mockDeleteLink).toHaveBeenCalledWith(0))
  })

  it('does not call deleteLink when dismissed', async () => {
    const mockDeleteLink = vi.fn()
    vi.mocked(confirmDanger).mockResolvedValue(false)
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [
        {
          type: 'existing',
          id: '1',
          url: 'https://example.com',
          label: 'Link to Delete',
          placements: {course_nav: true, account_nav: false, user_nav: false},
        },
      ],
      appendLink: vi.fn(),
      deleteLink: mockDeleteLink,
    })

    const {getByRole} = render(<NavMenuLinksSettings />)

    fireEvent.click(getByRole('button', {name: 'Delete Link to Delete'}))

    await waitFor(() => expect(confirmDanger).toHaveBeenCalled())
    expect(mockDeleteLink).not.toHaveBeenCalled()
  })

  it('renders hidden input with serialized links JSON', () => {
    const links = [
      {
        type: 'existing',
        id: '1',
        url: 'https://example.com/link-1',
        label: 'Link 1',
        placements: {course_nav: true, account_nav: false, user_nav: false},
      },
      {
        type: 'new',
        url: 'https://example.com/new',
        label: 'New Link',
        placements: {course_nav: true, account_nav: false, user_nav: false},
      },
    ]

    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links,
      appendLink: vi.fn(),
      deleteLink: vi.fn(),
    })

    const {container} = render(<NavMenuLinksSettings />)

    const hiddenInput = container.querySelector('input[name="account[nav_menu_links]"]')
    expect(hiddenInput).toBeInTheDocument()
    expect(hiddenInput?.getAttribute('value')).toBe(JSON.stringify(links))
  })

  it('shows url as external link for new links', () => {
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [
        {
          type: 'new',
          url: 'https://example.com/my-link',
          label: 'My Link',
          placements: {course_nav: true, account_nav: false, user_nav: false},
        },
      ],
      appendLink: vi.fn(),
      deleteLink: vi.fn(),
    })

    const {getByText, getByRole} = render(<NavMenuLinksSettings />)

    expect(getByText('My Link')).toBeInTheDocument()
    const link = getByRole('link', {name: /https:\/\/example\.com\/my-link/})
    expect(link).toHaveAttribute('href', 'https://example.com/my-link')
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('shows url as external link for existing links', () => {
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [
        {
          type: 'existing',
          id: '1',
          url: 'https://example.com/existing',
          label: 'Existing Link',
          placements: {course_nav: true, account_nav: false, user_nav: false},
        },
      ],
      appendLink: vi.fn(),
      deleteLink: vi.fn(),
    })

    const {getByText, getByRole} = render(<NavMenuLinksSettings />)

    expect(getByText('Existing Link')).toBeInTheDocument()
    const link = getByRole('link', {name: /https:\/\/example\.com\/existing/})
    expect(link).toHaveAttribute('href', 'https://example.com/existing')
    expect(link).toHaveAttribute('target', '_blank')
  })

  it('renders links in correct order', () => {
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [
        {
          type: 'existing',
          id: '1',
          url: 'https://example.com/first',
          label: 'First Link',
          placements: {course_nav: true, account_nav: false, user_nav: false},
        },
        {
          type: 'existing',
          id: '2',
          url: 'https://example.com/second',
          label: 'Second Link',
          placements: {course_nav: false, account_nav: true, user_nav: false},
        },
        {
          type: 'new',
          url: 'https://example.com',
          label: 'Third Link',
          placements: {course_nav: false, account_nav: false, user_nav: true},
        },
      ],
      appendLink: vi.fn(),
      deleteLink: vi.fn(),
    })

    const {container} = render(<NavMenuLinksSettings />)

    const listItems = container.querySelectorAll('.ic-Sortable-item')
    expect(listItems).toHaveLength(3)

    expect(within(listItems[0] as HTMLElement).getByText('First Link')).toBeInTheDocument()
    expect(within(listItems[1] as HTMLElement).getByText('Second Link')).toBeInTheDocument()
    expect(within(listItems[2] as HTMLElement).getByText('Third Link')).toBeInTheDocument()
  })
})
