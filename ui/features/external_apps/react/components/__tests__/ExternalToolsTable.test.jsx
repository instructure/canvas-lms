/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {ExternalToolsTable, countFavorites} from '../ExternalToolsTable'

function renderTable(canAdd = true, canEdit = true, canDelete = true, FEATURES = {}) {
  window.ENV = {
    context_asset_string: 'account_1',
    ACCOUNT: {
      site_admin: false,
    },
    FEATURES,
  }

  const setFocusAbove = jest.fn()
  return render(
    <ExternalToolsTable
      canAdd={canAdd}
      canEdit={canEdit}
      canDelete={canDelete}
      setFocusAbove={setFocusAbove}
    />,
  )
}

describe('ExternalToolsTable', () => {
  describe('rce favorites toggle', function () {
    it('shows if admin has permission', () => {
      const {queryByText} = renderTable()
      expect(queryByText('Name')).toBeInTheDocument()
      expect(queryByText('Add to RCE toolbar')).toBeInTheDocument()
    })

    it('does not show if admin does not have permission', () => {
      const {queryByText} = renderTable(false, false, false)
      expect(queryByText('Name')).toBeInTheDocument()
      expect(queryByText('Add to RCE toolbar')).not.toBeInTheDocument()
    })
  })

  describe('top nav favorites toggle', function () {
    it('shows if admin has permission', () => {
      const {queryByText} = renderTable(true, true, true, {top_navigation_placement: true})
      expect(queryByText('Name')).toBeInTheDocument()
      expect(queryByText('Pin to Top Navigation')).toBeInTheDocument()
    })

    it('does not show if admin does not have permission', () => {
      const {queryByText} = renderTable(false, false, false, {
        top_navigation_placement: true,
      })
      expect(queryByText('Name')).toBeInTheDocument()
      expect(queryByText('Pin to Top Navigation')).not.toBeInTheDocument()
    })

    it('does not show if feature flag is off', () => {
      const {queryByText} = renderTable(true, true, true, {top_navigation_placement: false})
      expect(queryByText('Name')).toBeInTheDocument()
      expect(queryByText('Pin to Top Navigation')).not.toBeInTheDocument()
    })
  })

  describe('calculateFavorites', () => {
    window.INST = {
      editorButtons: [],
    }
    it('returns 0 if externalTools array is empty', () => {
      const externalTools = []
      const rceFavCount = countFavorites(externalTools)
      expect(rceFavCount).toEqual(0)
    })

    it('returns 3 if externalTools contains 3 favorites and some not favorites', () => {
      const externalTools = [
        {is_rce_favorite: true},
        {is_rce_favorite: true},
        {is_rce_favorite: true},
        {is_rce_favorite: false},
      ]
      const rceFavCount = countFavorites(externalTools)
      expect(rceFavCount).toEqual(3)
    })

    it('returns 2 if externalTools contains 3 favorites but one of them is on_by_default', () => {
      window.INST = {
        editorButtons: [
          {id: 2, on_by_default: true},
          {id: 42, on_by_default: true},
        ],
      }
      const externalTools = [
        {app_id: 1, is_rce_favorite: true},
        {app_id: 2, is_rce_favorite: true},
        {app_id: 3, is_rce_favorite: true},
        {app_id: 4, is_rce_favorite: false},
      ]
      const rceFavCount = countFavorites(externalTools)
      expect(rceFavCount).toEqual(2)
    })
  })
})
