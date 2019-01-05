/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import $ from 'jquery'

import {mockAssignment} from '../../test-utils'
import DateTitle from '../DateTitle'

beforeAll(() => {
  const found = document.getElementById('fixtures')
  if (!found) {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)
  }
})

afterEach(() => {
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

it('renders title correctly', () => {
  const assignment = mockAssignment({name: 'Egypt Economy Research'})
  ReactDOM.render(<DateTitle assignment={assignment} />, document.getElementById('fixtures'))
  const title = $('[data-test-id="title"]')
  expect(title.text()).toEqual('Egypt Economy Research')
})

it('renders date correctly', () => {
  const assignment = mockAssignment({dueAt: '2016-07-11T18:00:00-01:00'})
  ReactDOM.render(<DateTitle assignment={assignment} />, document.getElementById('fixtures'))
  const title = $('[data-test-id="due-date-display"]')

  // Reason why this is showing up twice is once for screenreader content and again for regular content
  // Also, notice that it handles timezone differences here, with the `-01:00` offset
  expect(title.text()).toEqual('Due: Mon Jul 11, 2016 7:00pmDue: Mon Jul 11, 2016 7:00pm2016-7-11')
})

it('does not render a date if there is no dueAt set', () => {
  const assignment = mockAssignment({dueAt: null})
  ReactDOM.render(<DateTitle assignment={assignment} />, document.getElementById('fixtures'))
  const title = $('[data-test-id="due-date-display"]')
  expect(title).toHaveLength(0)
})
