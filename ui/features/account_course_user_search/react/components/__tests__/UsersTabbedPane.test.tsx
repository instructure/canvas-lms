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
import {render, screen, waitFor, fireEvent} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'
import UsersTabbedPane from '../UsersTabbedPane'

const usersPaneSpy = vi.fn()
vi.mock('../UsersPane', () => ({
  default: (props: Record<string, unknown>) => {
    usersPaneSpy(props)
    return <div data-testid="users-pane">Users Pane</div>
  },
}))

vi.mock('../AccountTagsPane', () => ({
  default: ({
    initialTagId,
    onTagSelect,
  }: {
    initialTagId?: string
    onTagSelect: (id: string | null) => void
  }) => (
    <div data-testid="account-tags-pane">
      <div data-testid="initial-tag-id">{initialTagId ?? 'none'}</div>
      <button type="button" onClick={() => onTagSelect('7')}>
        open-tag-7
      </button>
      <button type="button" onClick={() => onTagSelect(null)}>
        close-tag
      </button>
    </div>
  ),
}))

const fakeStore = () => ({
  getState: () => ({}),
  dispatch: () => undefined,
  subscribe: () => () => undefined,
})

const renderPane = (overrides: Partial<React.ComponentProps<typeof UsersTabbedPane>> = {}) => {
  const onUpdateQueryParams = vi.fn()
  const utils = render(
    <UsersTabbedPane
      store={fakeStore()}
      roles={[]}
      queryParams={{}}
      onUpdateQueryParams={onUpdateQueryParams}
      permissions={{can_view_institutional_tags: true}}
      {...overrides}
    />,
  )
  return {...utils, onUpdateQueryParams}
}

describe('UsersTabbedPane', () => {
  beforeEach(() => {
    fakeENV.setup({ROOT_ACCOUNT_ID: '1', PERMISSIONS: {can_view_institutional_tags: true}})
    usersPaneSpy.mockClear()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders the account tags tab with no initial tag id when tag_id is absent', async () => {
    renderPane({queryParams: {tab: 'account_tags'}})
    await waitFor(() => {
      expect(screen.getByTestId('initial-tag-id')).toHaveTextContent('none')
    })
  })

  it('forwards tag_id from queryParams as initialTagId on mount', async () => {
    renderPane({queryParams: {tab: 'account_tags', tag_id: '42'}})
    await waitFor(() => {
      expect(screen.getByTestId('initial-tag-id')).toHaveTextContent('42')
    })
  })

  it('writes the selected tag id to the URL via onTagSelect', async () => {
    const {onUpdateQueryParams} = renderPane({queryParams: {tab: 'account_tags'}})
    fireEvent.click(await screen.findByText('open-tag-7'))
    expect(onUpdateQueryParams).toHaveBeenCalledWith({tab: 'account_tags', tag_id: '7'})
  })

  it('drops tag_id from the URL when the tag is closed', async () => {
    const {onUpdateQueryParams} = renderPane({queryParams: {tab: 'account_tags'}})
    fireEvent.click(await screen.findByText('open-tag-7'))
    fireEvent.click(screen.getByText('close-tag'))
    expect(onUpdateQueryParams).toHaveBeenLastCalledWith({tab: 'account_tags'})
  })

  it('unmounts AccountTagsPane and clears tag_id when switching back to People', async () => {
    const {onUpdateQueryParams} = renderPane({queryParams: {tab: 'account_tags', tag_id: '42'}})
    await screen.findByTestId('account-tags-pane')
    fireEvent.click(screen.getByText('People'))
    await waitFor(() => {
      expect(screen.queryByTestId('account-tags-pane')).not.toBeInTheDocument()
    })
    expect(onUpdateQueryParams).toHaveBeenLastCalledWith({})
  })

  it('falls back to UsersPane when the user lacks the institutional tags permission', () => {
    renderPane({permissions: {can_view_institutional_tags: false}})
    expect(screen.getByTestId('users-pane')).toBeInTheDocument()
  })

  it('ignores tag_id in the URL when the institutional tags permission is missing', () => {
    renderPane({
      permissions: {can_view_institutional_tags: false},
      queryParams: {tab: 'account_tags', tag_id: '42'},
    })
    expect(screen.getByTestId('users-pane')).toBeInTheDocument()
    expect(screen.queryByTestId('account-tags-pane')).not.toBeInTheDocument()
  })

  it('forwards roles and queryParams through to UsersPane', () => {
    const roles = [{id: '3', label: 'Teacher'}]
    const queryParams = {search_term: 'alice', role_filter_id: '3'}
    renderPane({roles, queryParams})
    expect(usersPaneSpy).toHaveBeenCalledWith(expect.objectContaining({roles, queryParams}))
  })
})
