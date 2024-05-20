/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import UsersToolbar from '../UsersToolbar'
import {render} from '@testing-library/react'

const props = {
  toggleSRMessage: () => {},
  onApplyFilters: () => {},
  onUpdateFilters: jest.fn(),
  isLoading: true,
  errors: {search_term: ''},
}

let old_env

describe('UsersToolbar', () => {
  beforeEach(() => {
    old_env = window.ENV
    window.ENV = {
      PERMISSIONS: { can_edit_users: true },
      FEATURES: { granular_permissions_manage_users: true },
    }
  })

  afterEach(() => {
    window.ENV = old_env
  })

  describe('Filtering', () => {
    it('onUpdateFilter is called when deleted user checkbox is clicked', () => {
      const {getByText} = render(<UsersToolbar {...props} />)
      const enrollCheck = getByText('Include deleted users in search results')

      enrollCheck.click()
      expect(props.onUpdateFilters).toHaveBeenCalledWith({include_deleted_users: true})
    })
  })
})
