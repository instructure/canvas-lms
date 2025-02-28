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
import {Collaborations} from '../Collaborations'
import {HorizonToggleContext} from '../../HorizonToggleContext'

describe('Collaborations', () => {
  const mockData = {
    errors: {
      collaborations: [
        {
          id: 1,
          name: 'Collab 1',
          link: '/collab1',
          errors: {
            peer_reviews: {
              attribute: 'peer_reviews',
              type: 'unsupported',
              message: 'Peer reviews not supported',
            },
          },
        },
        {
          id: 2,
          name: 'Collab 2',
          link: '/collab2',
          errors: {
            peer_reviews: {
              attribute: 'peer_reviews',
              type: 'unsupported',
              message: 'Peer reviews not supported',
            },
          },
        },
      ],
    },
  }

  it('renders nothing when no collaboration errors exist', () => {
    render(
      <HorizonToggleContext.Provider value={{errors: {}}}>
        <Collaborations />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.queryByText(/Collaborations/)).not.toBeInTheDocument()
  })

  it('renders collaboration items when errors exist', async () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <Collaborations />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Collaborations (2 items)')).toBeInTheDocument()
    const toggle = screen.getByText('Collaborations')
    toggle.click()
    expect(screen.getByText('Collab 1')).toBeInTheDocument()
    expect(screen.getByText('Collab 2')).toBeInTheDocument()
  })

  it('renders the correct translation for single item', () => {
    render(
      <HorizonToggleContext.Provider
        value={{
          errors: {
            collaborations: [
              {
                id: 1,
                name: 'Collab 1',
                link: '/collab1',
                errors: {
                  peer_reviews: {
                    attribute: 'peer_reviews',
                    type: 'unsupported',
                    message: 'Peer reviews not supported',
                  },
                },
              },
            ],
          },
        }}
      >
        <Collaborations />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Collaborations (1 item)')).toBeInTheDocument()
    const toggle = screen.getByText('Collaborations')
    toggle.click()
    expect(screen.getByText('Collab 1')).toBeInTheDocument()
  })
})
