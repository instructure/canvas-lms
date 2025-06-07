// @vitest-environment jsdom
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {act, render as testingLibraryRender, waitFor} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
import {defaultK5DashboardProps as defaultProps} from './mocks'
import {MockedQueryProvider} from '@canvas/test-utils/query'

jest.useFakeTimers()

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const server = setupServer(
  http.get('/api/v1/dashboard/dashboard_cards', () => HttpResponse.json([])),
)

// getByRole() causes these tests to be very slow, so provide a much faster helper
// function that does the same thing
function findTabByName(tabName, opts) {
  const tabElement = document.getElementById(`tab-tab-${tabName.toLowerCase()}`)

  if (!tabElement) {
    throw new Error(`tab ${tabName} not found in DOM`)
  }

  const actualSelectedValue = tabElement.getAttribute('aria-selected') || 'false'
  const expectedSelectedValue = opts?.selected ? 'true' : 'false'

  if (actualSelectedValue !== expectedSelectedValue) {
    throw new Error(
      `tab ${tabName} found in DOM, but had incorrect selected state of ${expectedSelectedValue} (was: ${actualSelectedValue})`,
    )
  }

  return tabElement
}

describe('K5Dashboard Tabs', () => {
  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
    window.location.hash = ''
  })

  afterAll(() => {
    server.close()
  })

  it('show Homeroom, Schedule, Grades, and Resources options', async () => {
    const {getByText} = render(<K5Dashboard {...defaultProps} />)
    await waitFor(() => {
      ;['Homeroom', 'Schedule', 'Grades', 'Resources'].forEach(label =>
        expect(getByText(label)).toBeInTheDocument(),
      )
    })
  })

  it('default to the Homeroom tab', async () => {
    render(<K5Dashboard {...defaultProps} />)
    expect(findTabByName('Homeroom', {selected: true})).toBeInTheDocument()
  })
  describe('store current tab ID to URL', () => {
    afterEach(() => {
      window.location.hash = ''
    })

    it('and start at that tab if it is valid', async () => {
      window.location.hash = '#grades'
      render(<K5Dashboard {...defaultProps} />)
      expect(findTabByName('Grades', {selected: true})).toBeInTheDocument()
    })

    it('and start at the default tab if it is invalid', async () => {
      window.location.hash = 'tab-not-a-real-tab'
      render(<K5Dashboard {...defaultProps} />)
      expect(findTabByName('Homeroom', {selected: true})).toBeInTheDocument()
    })

    it('and update the current tab as tabs are changed', async () => {
      render(<K5Dashboard {...defaultProps} />)

      act(() => findTabByName('Grades', {selected: false}).click())
      await act(async () => jest.runAllTimers())
      expect(findTabByName('Grades', {selected: true})).toBeInTheDocument()

      act(() => findTabByName('Resources', {selected: false}).click())
      await act(async () => jest.runAllTimers())

      expect(findTabByName('Grades', {selected: false})).toBeInTheDocument()
      expect(findTabByName('Resources', {selected: true})).toBeInTheDocument()
    })
  })
})
