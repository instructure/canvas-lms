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
import {render} from '@testing-library/react'
import HelpTray from '../HelpTray'

describe('HelpTray', () => {
  const trayTitle = 'Halp'
  const links = [
    {
      text: 'Search the Canvas Guides',
      subtext: 'Find answers to common questions',
      url: 'http://community.canvaslms.com/community/answers/guides',
      type: 'default',
      id: 'search_the_canvas_guides'
    },
    {
      text: 'Report a Problem',
      subtext: 'If Canvas misbehaves, tell us about it',
      url: '#create_ticket',
      type: 'default',
      id: 'report_a_problem'
    }
  ]

  const props = {
    trayTitle,
    links,
    hasLoaded: true
  }

  it('renders loading spinner', () => {
    const {getByTitle, queryByText} = render(<HelpTray {...props} hasLoaded={false} />)
    getByTitle('Loading')
    expect(queryByText('Search the Canvas Guides')).toBeNull()
    expect(queryByText('Report a Problem')).toBeNull()
  })

  it('renders title header', () => {
    const {getByText} = render(<HelpTray {...props} />)
    expect(getByText('Halp')).toBeVisible()
  })

  it('renders help dialog links', () => {
    const {getByText} = render(<HelpTray {...props} />)
    getByText('Search the Canvas Guides')
    getByText('Report a Problem')
  })
})
