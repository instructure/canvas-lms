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
import {Outcomes} from '../Outcomes'
import {HorizonToggleContext} from '../../HorizonToggleContext'

describe('Outcomes', () => {
  const mockData = {
    errors: {
      outcomes: [
        {
          id: 1,
          name: 'Outcome 1',
          link: '/outcome1',
          errors: {
            rubric: {
              attribute: 'rubric',
              type: 'unsupported',
              message: 'Rubric not supported',
            },
          },
        },
        {
          id: 2,
          name: 'Outcome 2',
          link: '/outcome2',
          errors: {
            rubric: {
              attribute: 'rubric',
              type: 'unsupported',
              message: 'Rubric not supported',
            },
          },
        },
      ],
    },
  }

  it('renders nothing when no outcome errors exist', () => {
    render(
      <HorizonToggleContext.Provider value={{errors: {}}}>
        <Outcomes />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.queryByText(/Outcomes/)).not.toBeInTheDocument()
  })

  it('renders outcome items when errors exist', async () => {
    render(
      <HorizonToggleContext.Provider value={mockData}>
        <Outcomes />
      </HorizonToggleContext.Provider>,
    )

    expect(screen.getByText('Outcomes (2 items)')).toBeInTheDocument()
    const toggle = screen.getByText('Outcomes')
    toggle.click()
    expect(screen.getByText('Outcome 1')).toBeInTheDocument()
    expect(screen.getByText('Outcome 2')).toBeInTheDocument()
  })

  it('displays correct translation for single item', () => {
    render(
      <HorizonToggleContext.Provider
        value={{
          errors: {
            outcomes: [
              {
                id: 1,
                name: 'Outcome 1',
                link: '/outcome1',
                errors: {
                  rubric: {
                    attribute: 'rubric',
                    type: 'unsupported',
                    message: 'Rubric not supported',
                  },
                },
              },
            ],
          },
        }}
      >
        <Outcomes />
      </HorizonToggleContext.Provider>,
    )
    expect(screen.getByText('Outcomes (1 item)')).toBeInTheDocument()
    const toggle = screen.getByText('Outcomes')
    toggle.click()
    expect(screen.getByText('Outcome 1')).toBeInTheDocument()
  })
})
