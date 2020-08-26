/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {act, render, fireEvent, wait} from '@testing-library/react'
import $ from 'jquery'
import store from '../../lib/ExternalAppsStore'
import ExternalToolsTableRow from '../ExternalToolsTableRow'

const tools = [
  {
    app_id: 1,
    context: 'Account',
    context_id: 1,
    description: 'This is tool 1',
    name: 'Tool 1',
    is_rce_favorite: false
  },
  {
    app_id: 2,
    context: 'Account',
    context_id: 1,
    description: 'This is tool 2',
    name: 'Tool 2',
    is_rce_favorite: true
  },
  {
    app_id: 3,
    context: 'Account',
    context_id: 1,
    description: 'This is tool 3',
    name: 'Tool 3'
  }
]

const ajax = $.ajax
beforeEach(() => {
  store.setState({
    externalTools: tools,
    hasMore: false,
    isLoaded: true,
    isLoading: false
  })
})

afterEach(() => {
  $.ajax = ajax
})

function renderRow(props) {
  const table = document.createElement('table')
  const tbody = document.createElement('tbody')
  table.appendChild(tbody)
  document.body.appendChild(table)
  return render(
    <ExternalToolsTableRow
      tool={tools[0]}
      canAddEdit
      setFocusAbove={() => {}}
      favoriteCount={0}
      contextType="account"
      {...props}
    />,
    {
      container: tbody
    }
  )
}

describe('ExternalToolsTableRow', () => {
  describe('without lti_favorites', () => {
    it('does not show the toggle', () => {
      const {queryByLabelText} = renderRow({showLTIFavoriteToggles: false})
      expect(queryByLabelText('Favorite')).not.toBeInTheDocument()
    })
  })

  describe('with the lti_favorites', () => {
    it('shows toggle with current tool favorite state when false', () => {
      const {getByLabelText} = renderRow({showLTIFavoriteToggles: true})
      expect(getByLabelText('Favorite')).toBeInTheDocument()
      const checkbox = getByLabelText('Favorite').closest('input[type="checkbox"]')
      expect(checkbox.checked).toBe(false)
    })

    it('shows toggle with current tool favorite state when true', () => {
      const {getByLabelText} = renderRow({tool: tools[1], showLTIFavoriteToggles: true})
      expect(getByLabelText('Favorite')).toBeInTheDocument()
      const checkbox = getByLabelText('Favorite').closest('input[type="checkbox"]')
      expect(checkbox.checked).toBe(true)
    })

    it('does not show the toggle when tool cannot be a favorite', () => {
      const {getByText, queryByLabelText} = renderRow({
        tool: tools[2],
        showLTIFavoriteToggles: true
      })
      expect(queryByLabelText('Favorite')).not.toBeInTheDocument()
      expect(getByText('NA')).toBeInTheDocument()
    })

    it('disables toggle if 2 tools are already favorites and this row is not a favorite', () => {
      const {getByLabelText} = renderRow({favoriteCount: 2, showLTIFavoriteToggles: true})

      const checkbox = getByLabelText('Favorite').closest('input[type="checkbox"]')
      expect(checkbox.disabled).toBe(true)
    })

    it('enables toggle if 2 tools are already favorites and this row is a favorite', () => {
      const {getByLabelText} = renderRow({
        tool: tools[1],
        favoriteCount: 2,
        showLTIFavoriteToggles: true
      })

      const checkbox = getByLabelText('Favorite').closest('input[type="checkbox"]')
      expect(checkbox.disabled).toBe(false)
    })

    it('calls store.setAsFavorite when toggle is flipped', () => {
      const {getByLabelText} = renderRow({showLTIFavoriteToggles: true})
      expect(getByLabelText('Favorite')).toBeInTheDocument()
      const setAsFav = store.setAsFavorite
      store.setAsFavorite = jest.fn()

      const checkbox = getByLabelText('Favorite').closest('input[type="checkbox"]')
      fireEvent.click(checkbox)

      expect(store.setAsFavorite).toHaveBeenCalled()
      store.setAsFavorite = setAsFav
    })

    it('updates the store on successfully updating canvas db', async () => {
      $.ajax = opts => {
        setTimeout(opts.success, 1)
      }

      const {getByLabelText} = renderRow({showLTIFavoriteToggles: true})
      expect(store.getState().externalTools[0].is_rce_favorite).toBe(false)
      act(() => {
        const checkbox = getByLabelText('Favorite').closest('input[type="checkbox"]')
        fireEvent.click(checkbox)
      })
      await wait(() => expect(store.getState().externalTools[0].is_rce_favorite).toBe(true))
    })
  })
})
