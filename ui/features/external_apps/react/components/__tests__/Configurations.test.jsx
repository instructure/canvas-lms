/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import Configurations from '../Configurations'

describe('ExternalApps.Configurations', () => {
  const renderComponent = (props = {}) => {
    return render(<Configurations {...props} />)
  }

  it('renders', () => {
    const {container} = renderComponent({env: {APP_CENTER: {enabled: true}}})
    expect(container).toBeInTheDocument()
  })

  describe('permissions', () => {
    it('shows add button when add_tool_manually permission is true', () => {
      const {getByRole} = renderComponent({
        env: {
          PERMISSIONS: {add_tool_manually: true},
          APP_CENTER: {enabled: true},
        },
      })
      expect(getByRole('button', {name: /add app/i})).toBeInTheDocument()
    })

    it('hides add button when add_tool_manually permission is false', () => {
      const {queryByRole} = renderComponent({
        env: {
          PERMISSIONS: {add_tool_manually: false},
          APP_CENTER: {enabled: true},
        },
      })
      expect(queryByRole('button', {name: /add app/i})).not.toBeInTheDocument()
    })

    it('shows external tools table when edit_tool_manually permission is true', () => {
      const {getByTestId} = renderComponent({
        env: {
          PERMISSIONS: {edit_tool_manually: true},
          APP_CENTER: {enabled: true},
        },
      })
      expect(getByTestId('dev-key-admin-table')).toBeInTheDocument()
    })

    it('shows external tools table when edit_tool_manually permission is false', () => {
      const {getByTestId} = renderComponent({
        env: {
          PERMISSIONS: {edit_tool_manually: false},
          APP_CENTER: {enabled: true},
        },
      })
      expect(getByTestId('dev-key-admin-table')).toBeInTheDocument()
    })

    it('shows external tools table when delete_tool_manually permission is true', () => {
      const {getByTestId} = renderComponent({
        env: {
          PERMISSIONS: {delete_tool_manually: true},
          APP_CENTER: {enabled: true},
        },
      })
      expect(getByTestId('dev-key-admin-table')).toBeInTheDocument()
    })

    it('shows external tools table when delete_tool_manually permission is false', () => {
      const {getByTestId} = renderComponent({
        env: {
          PERMISSIONS: {delete_tool_manually: false},
          APP_CENTER: {enabled: true},
        },
      })
      expect(getByTestId('dev-key-admin-table')).toBeInTheDocument()
    })
  })
})
