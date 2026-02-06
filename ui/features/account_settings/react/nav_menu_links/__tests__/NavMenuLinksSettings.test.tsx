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
import {render, fireEvent, within} from '@testing-library/react'
import NavMenuLinksSettings from '../NavMenuLinksSettings'
import {useNavMenuLinksStore} from '../useNavMenuLinksStore'

// Mock the store
vi.mock('../useNavMenuLinksStore')

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

  it('calls deleteLink when delete is clicked', () => {
    const mockDeleteLink = vi.fn()
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [{type: 'existing', id: '1', label: 'Link to Delete'}],
      appendLink: vi.fn(),
      deleteLink: mockDeleteLink,
    })

    const {getByRole, getByText} = render(<NavMenuLinksSettings />)

    const menuButton = getByRole('button', {name: /Settings for Link to Delete/i})
    fireEvent.click(menuButton)

    const deleteButton = getByRole('menuitem', {name: /Delete/i})
    fireEvent.click(deleteButton)

    expect(mockDeleteLink).toHaveBeenCalledWith(0)
  })

  it('renders hidden input with serialized links JSON', () => {
    const links = [
      {type: 'existing', id: '1', label: 'Link 1'},
      {type: 'new', url: 'https://example.com/new', label: 'New Link'},
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

  it('renders links in correct order', () => {
    vi.mocked(useNavMenuLinksStore).mockReturnValue({
      links: [
        {type: 'existing', id: '1', label: 'First Link'},
        {type: 'existing', id: '2', label: 'Second Link'},
        {type: 'new', url: 'https://example.com', label: 'Third Link'},
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
