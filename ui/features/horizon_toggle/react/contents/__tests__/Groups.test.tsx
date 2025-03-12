/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {Groups} from '../Groups'
import {HorizonToggleContext} from '../../HorizonToggleContext'

describe('Groups', () => {
  const mockData = {
    errors: {
      groups: [
        {
          id: 1,
          name: 'Group 1',
          link: '/group1',
          errors: {
            group_category: {
              attribute: 'category',
              type: 'unsupported',
              message: 'Group category not supported',
            },
          },
        },
        {
          id: 2,
          name: 'Group 2',
          link: '/group2',
          errors: {
            group_category: {
              attribute: 'category',
              type: 'unsupported',
              message: 'Group category not supported',
            },
          },
        },
      ],
    },
  }

  it('renders group items when errors exist', async () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <Groups />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Groups (2 items)')).toBeInTheDocument()
    const toggle = screen.getByText('Groups')
    toggle.click()
    expect(screen.getByText('Group 1')).toBeInTheDocument()
    expect(screen.getByText('Group 2')).toBeInTheDocument()
  })

  it('displays correct translation for single item', () => {
    render(
      <HorizonToggleContext.Provider
        value={{
          errors: {
            groups: [
              {
                id: 1,
                name: 'Group 1',
                link: '/group1',
                errors: {
                  group_category: {
                    attribute: 'category',
                    type: 'unsupported',
                    message: 'Group category not supported',
                  },
                },
              },
            ],
          },
        }}
      >
        <Groups />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Groups (1 item)')).toBeInTheDocument()
    const toggle = screen.getByText('Groups')
    toggle.click()
    expect(screen.getByText('Group 1')).toBeInTheDocument()
  })
})
