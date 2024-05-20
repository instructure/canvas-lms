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
import ViolationTray from '../ViolationTray'
import {render} from '@testing-library/react'
import fetchMock from 'fetch-mock' // import fetch-mock

describe('Violation Tray', () => {
  beforeEach(() => {
    fetchMock.restore() // Reset mocks
  })

  const getProps = overrides => ({
    violations: [],
    whitelistedDomains: {account: []},
    ...overrides,
  })

  it('displays a spinner when loading data', async () => {
    fetchMock.mock('*', JSON.stringify([])) // Mock fetch
    const {findByText} = render(<ViolationTray {...getProps()} />)
    await findByText('Loading')
  })

  it('displays an error alert when an error loading occurs', async () => {
    fetchMock.mock('*', {throws: new Error('fail')}) // Mock fetch with error
    const {findByText} = render(<ViolationTray {...getProps()} />)
    expect(await findByText(/Something went wrong loading/)).toBeInTheDocument()
  })

  it('displays an info alert when there are no violations', async () => {
    fetchMock.mock('*', JSON.stringify([])) // Mock fetch
    const {findByText} = render(<ViolationTray {...getProps()} />)
    expect(await findByText(/No violations/)).toBeInTheDocument()
  })

  it('displays the violation table when there are violations', async () => {
    fetchMock.mock(
      '*',
      JSON.stringify([
        {
          uri: 'http://example.com',
          latest_hit: '2019-11-11T00:00:00.000Z',
          count: 7,
        },
        {
          uri: 'http://clayd.dev',
          latest_hit: '2019-11-11T00:00:00.000Z',
          count: 2,
        },
      ])
    ) // Mock fetch with data
    const {findByText} = render(<ViolationTray {...getProps()} />)
    await findByText(/CSP Violations/)
  })
})
