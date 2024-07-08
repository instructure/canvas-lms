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
import {act, render, fireEvent, waitFor} from '@testing-library/react'
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
    is_rce_favorite: false,
    is_top_nav_favorite: false,
    editor_button_settings: {enabled: true},
    installed_locally: true,
    restricted_by_master_course: false,
    top_navigation_settings: {enabled: true},
  },
  {
    app_id: 2,
    context: 'Account',
    context_id: 1,
    description: 'This is tool 2',
    name: 'Tool 2',
    is_rce_favorite: true,
    is_top_nav_favorite: true,
    editor_button_settings: {enabled: true},
    top_navigation_settings: {enabled: true},
  },
  {
    app_id: 3,
    context: 'Account',
    context_id: 1,
    description: 'This is tool 3',
    name: 'Tool 3',
  },
  {
    app_id: 4,
    context: 'Account',
    context_id: 1,
    description: 'This is tool 4',
    name: 'Tool 4',
    is_rce_favorite: true,
    is_top_nav_favorite: true,
    editor_button_settings: {enabled: false},
    top_navigation_settings: {enabled: false},
  },
]

const ajax = $.ajax
beforeEach(() => {
  store.setState({
    externalTools: tools,
    hasMore: false,
    isLoaded: true,
    isLoading: false,
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
  window.ENV.FEATURES = {top_navigation_placement: true}
  return render(
    <ExternalToolsTableRow
      tool={tools[0]}
      canAdd={true}
      canEdit={true}
      canDelete={true}
      canAddEdit={true}
      setFocusAbove={() => {}}
      rceFavoriteCount={0}
      topNavFavoriteCount={0}
      contextType="account"
      {...props}
    />,
    {
      container: tbody,
    }
  )
}

describe('ExternalToolsTableRow', () => {
  describe('with permissions to render', () => {
    it('shows the settings COG dropdown button', () => {
      const {queryByText} = renderRow()
      expect(queryByText(`${tools[0].name} Settings`)).toBeInTheDocument()
    })
  })

  describe('without permissions to render', () => {
    it('shows the external tool placement in replace of the settings COG', () => {
      const {queryByText} = renderRow({
        canEdit: false,
        canDelete: false,
        canAddEdit: false,
      })
      expect(queryByText(`${tools[0].name} Settings`)).not.toBeInTheDocument()
    })
  })

  describe('without lti_favorites', () => {
    it('does not show the toggle', () => {
      const {queryByLabelText} = renderRow({showLTIFavoriteToggles: false})
      expect(queryByLabelText('RCE Favorite')).not.toBeInTheDocument()
      expect(queryByLabelText('Top Navigation Favorite')).not.toBeInTheDocument()
    })
  })

  describe('with the lti_favorites', () => {
    it('shows toggle with current tool favorite state when false and Editor placement is active', () => {
      const {getByLabelText} = renderRow({showLTIFavoriteToggles: true})
      expect(getByLabelText('RCE Favorite')).toBeInTheDocument()
      expect(getByLabelText('Top Navigation Favorite')).toBeInTheDocument()
      const checkbox = getByLabelText('RCE Favorite').closest('input[type="checkbox"]')
      expect(checkbox.checked).toBe(false)
      const checkbox2 = getByLabelText('Top Navigation Favorite').closest('input[type="checkbox"]')
      expect(checkbox2.checked).toBe(false)
    })

    it('shows toggle with current tool favorite state when true and Editor placement is active', () => {
      const {getByLabelText} = renderRow({tool: tools[1], showLTIFavoriteToggles: true})
      expect(getByLabelText('RCE Favorite')).toBeInTheDocument()
      expect(getByLabelText('Top Navigation Favorite')).toBeInTheDocument()
      const checkbox = getByLabelText('RCE Favorite').closest('input[type="checkbox"]')
      expect(checkbox.checked).toBe(true)
      const checkbox2 = getByLabelText('Top Navigation Favorite').closest('input[type="checkbox"]')
      expect(checkbox2.checked).toBe(true)
    })

    it('does not show the toggle when tool cannot be a favorite', () => {
      const {getAllByText, queryByLabelText} = renderRow({
        tool: tools[2],
        showLTIFavoriteToggles: true,
      })
      expect(queryByLabelText('RCE Favorite')).not.toBeInTheDocument()
      expect(queryByLabelText('Top Navigation Favorite')).not.toBeInTheDocument()
      expect(getAllByText('NA')).toHaveLength(2)
    })

    it('does not show the toggle when Editor button placement is inactive', () => {
      const {getAllByText, queryByLabelText} = renderRow({
        tool: tools[3],
        showLTIFavoriteToggles: true,
      })
      expect(queryByLabelText('RCE Favorite')).not.toBeInTheDocument()
      expect(queryByLabelText('Top Navigation Favorite')).not.toBeInTheDocument()
      expect(getAllByText('NA')).toHaveLength(2)
    })

    it('disables toggle if 2 tools are already favorites and this row is not a favorite', () => {
      const {getByLabelText} = renderRow({
        rceFavoriteCount: 2,
        topNavFavoriteCount: 2,
        showLTIFavoriteToggles: true,
      })

      const checkbox = getByLabelText('RCE Favorite').closest('input[type="checkbox"]')
      expect(checkbox.disabled).toBe(true)
      const checkbox2 = getByLabelText('Top Navigation Favorite').closest('input[type="checkbox"]')
      expect(checkbox2.disabled).toBe(true)
    })

    it('enables toggle if 2 tools are already favorites and this row is a favorite', () => {
      const {getByLabelText} = renderRow({
        tool: tools[1],
        rceFavoriteCount: 2,
        topNavFavoriteCount: 2,
        showLTIFavoriteToggles: true,
      })

      const checkbox = getByLabelText('RCE Favorite').closest('input[type="checkbox"]')
      expect(checkbox.disabled).toBe(false)
      const checkbox2 = getByLabelText('Top Navigation Favorite').closest('input[type="checkbox"]')
      expect(checkbox2.disabled).toBe(false)
    })

    it('calls store.setAsFavorite when toggle is flipped', () => {
      const {getByLabelText} = renderRow({showLTIFavoriteToggles: true})
      expect(getByLabelText('RCE Favorite')).toBeInTheDocument()
      expect(getByLabelText('Top Navigation Favorite')).toBeInTheDocument()
      const setAsFav = store.setAsFavorite
      store.setAsFavorite = jest.fn()

      const checkbox = getByLabelText('RCE Favorite').closest('input[type="checkbox"]')
      fireEvent.click(checkbox)
      expect(store.setAsFavorite).toHaveBeenCalled()

      const checkbox2 = getByLabelText('Top Navigation Favorite').closest('input[type="checkbox"]')
      fireEvent.click(checkbox2)
      expect(store.setAsFavorite).toHaveBeenCalled()

      store.setAsFavorite = setAsFav
    })

    it('updates the store on successfully updating canvas db', async () => {
      $.ajax = opts => {
        setTimeout(opts.success, 1)
      }

      const {getByLabelText} = renderRow({showLTIFavoriteToggles: true})
      expect(store.getState().externalTools[0].is_rce_favorite).toBe(false)
      expect(store.getState().externalTools[0].is_top_nav_favorite).toBe(false)
      act(() => {
        const checkbox = getByLabelText('RCE Favorite').closest('input[type="checkbox"]')
        fireEvent.click(checkbox)
        const checkbox2 =
          getByLabelText('Top Navigation Favorite').closest('input[type="checkbox"]')
        fireEvent.click(checkbox2)
      })
      await waitFor(() => expect(store.getState().externalTools[0].is_rce_favorite).toBe(true))
      await waitFor(() => expect(store.getState().externalTools[0].is_top_nav_favorite).toBe(true))
    })
  })
})
