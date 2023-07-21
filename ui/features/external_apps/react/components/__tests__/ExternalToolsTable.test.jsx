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
import ExternalToolsTable from '../ExternalToolsTable'

function renderTable(canAdd = true, canEdit = true, canDelete = true, canAddEdit = true) {
  window.ENV = {
    context_asset_string: 'account_1',
    ACCOUNT: {
      site_admin: false,
    },
    FEATURES: {},
  }

  const setFocusAbove = jest.fn()
  return render(
    <ExternalToolsTable
      canAdd={canAdd}
      canEdit={canEdit}
      canDelete={canDelete}
      canAddEdit={canAddEdit}
      setFocusAbove={setFocusAbove}
    />
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
      const {queryByText} = renderTable(false, false, false, false)
      expect(queryByText('Name')).toBeInTheDocument()
      expect(queryByText('Add to RCE toolbar')).not.toBeInTheDocument()
    })
  })
})
