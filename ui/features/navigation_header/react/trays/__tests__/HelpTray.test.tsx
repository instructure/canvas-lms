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
import {render as testingLibraryRender, screen} from '@testing-library/react'
import HelpTray from '../HelpTray'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

const props = {
  closeTray: vi.fn(),
  badgeDisabled: false,
  setBadgeDisabled: vi.fn(),
  forceUnreadPoll: vi.fn(),
}
const render = () => {
  return testingLibraryRender(
    <MockedQueryProvider>
      <HelpTray {...props} />
    </MockedQueryProvider>,
  )
}

describe('HelpTray', () => {
  const links = [
    {
      text: 'Search the Canvas Guides',
      subtext: 'Find answers to common questions',
      url: 'https://community.canvaslms.test/t5/Canvas/ct-p/canvas',
      type: 'default',
      id: 'search_the_canvas_guides',
    },
    {
      text: 'Report a Problem',
      subtext: 'If Canvas misbehaves, tell us about it',
      url: '#create_ticket',
      type: 'default',
      id: 'report_a_problem',
    },
  ]

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    // Default handler for help_links API
    server.use(http.get('/help_links', () => HttpResponse.json([])))
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.removeQueries()
  })

  it('renders title header', () => {
    window.ENV.help_link_name = 'Halp'

    render()

    expect(screen.getByText('Halp')).toBeVisible()
  })

  it('renders help dialog links', () => {
    queryClient.setQueryData(['helpLinks'], links)

    render()

    expect(screen.getByText('Search the Canvas Guides')).toBeVisible()
    expect(screen.getByText('Report a Problem')).toBeVisible()
  })
})
