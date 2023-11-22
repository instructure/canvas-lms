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
import {render as testingLibraryRender} from '@testing-library/react'
import HelpTray from '../HelpTray'
import {QueryProvider, queryClient} from '@canvas/query'

const render = (children: unknown) =>
  testingLibraryRender(<QueryProvider>{children}</QueryProvider>)

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

  const props = {
    closeTray: jest.fn(),
    badgeDisabled: false,
    setBadgeDisabled: jest.fn(),
    forceUnreadPoll: jest.fn(),
  }

  beforeEach(() => {
    // @ts-expect-error
    window.ENV = {FEATURES: {featured_help_links: true}}
  })

  afterEach(() => {
    // @ts-expect-error
    window.ENV = {}
    queryClient.removeQueries()
  })

  it('renders title header', () => {
    window.ENV.help_link_name = 'Halp'
    const {getByText} = render(<HelpTray {...props} />)
    expect(getByText('Halp')).toBeVisible()
  })

  it('renders help dialog links', () => {
    queryClient.setQueryData(['helpLinks'], links)
    const {getByText} = render(<HelpTray {...props} />)
    getByText('Search the Canvas Guides')
    getByText('Report a Problem')
  })
})
