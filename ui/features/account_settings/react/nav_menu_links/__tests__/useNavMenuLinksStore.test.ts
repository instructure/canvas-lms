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

import {renderHook, act} from '@testing-library/react-hooks'

// Mock ENV before importing
// @ts-expect-error
global.ENV = {NAV_MENU_LINKS: []}

import {useNavMenuLinksStore} from '../useNavMenuLinksStore'

describe('useNavMenuLinksStore', () => {
  beforeEach(() => {
    // Reset store to clean state before each test
    useNavMenuLinksStore.setState({links: []})
  })

  it('appendLink adds a new link with type "new"', () => {
    const {result} = renderHook(() => useNavMenuLinksStore())

    act(() => {
      result.current.appendLink({url: 'https://example.com', label: 'Test Link'})
    })

    expect(result.current.links).toHaveLength(1)
    expect(result.current.links[0]).toEqual({
      type: 'new',
      url: 'https://example.com',
      label: 'Test Link',
    })
  })

  it('deleteLink removes a link at the specified index', () => {
    const {result} = renderHook(() => useNavMenuLinksStore())

    // Set up initial state with two links
    act(() => {
      useNavMenuLinksStore.setState({
        links: [
          {type: 'existing', id: '1', label: 'Link 1'},
          {type: 'existing', id: '2', label: 'Link 2'},
        ],
      })
    })

    expect(result.current.links).toHaveLength(2)

    // Delete the first link
    act(() => {
      result.current.deleteLink(0)
    })

    expect(result.current.links).toHaveLength(1)
    expect(result.current.links[0]).toEqual({type: 'existing', id: '2', label: 'Link 2'})
  })
})
