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
import {Discussions} from '../Discussions'
import {HorizonToggleContext} from '../../HorizonToggleContext'

describe('Discussions', () => {
  const mockData = {
    errors: {
      discussions: [
        {
          id: 1,
          name: 'Discussion 1',
          link: '/discussion1',
          errors: {
            discussion_type: {
              attribute: 'type',
              type: 'unsupported',
              message: 'Discussion type not supported',
            },
          },
        },
        {
          id: 2,
          name: 'Discussion 2',
          link: '/discussion2',
          errors: {
            discussion_type: {
              attribute: 'type',
              type: 'unsupported',
              message: 'Discussion type not supported',
            },
          },
        },
      ],
    },
  }

  it('renders nothing when no discussion errors exist', () => {
    render(
      <HorizonToggleContext.Provider value={{errors: {}}}>
        <Discussions />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.queryByText(/Discussions/)).not.toBeInTheDocument()
  })

  it('renders discussion items when errors exist', async () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <Discussions />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Discussions (2 items)')).toBeInTheDocument()
    const toggle = screen.getByText('Discussions')
    toggle.click()
    expect(screen.getByText('Discussion 1')).toBeInTheDocument()
    expect(screen.getByText('Discussion 2')).toBeInTheDocument()
  })

  it('displays correct translation for single item', () => {
    render(
      <HorizonToggleContext.Provider
        value={{
          errors: {
            discussions: [
              {
                id: 1,
                name: 'Discussion 1',
                link: '/discussion1',
                errors: {
                  discussion_type: {
                    attribute: 'type',
                    type: 'unsupported',
                    message: 'Discussion type not supported',
                  },
                },
              },
            ],
          },
        }}
      >
        <Discussions />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Discussions (1 item)')).toBeInTheDocument()
    const toggle = screen.getByText('Discussions')
    toggle.click()
    expect(screen.getByText('Discussion 1')).toBeInTheDocument()
  })
})
