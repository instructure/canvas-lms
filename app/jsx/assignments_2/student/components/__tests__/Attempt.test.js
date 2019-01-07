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
import Attempt from '../Attempt'

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

it('renders attempt line correctly with unlimited allowed attempts', () => {
  ReactDOM.render(<Attempt assignment={mockAssignment()} />, document.getElementById('fixtures'))
  const attempt_line = $('[data-test-id="attempt"]')
  expect(attempt_line.text()).toEqual('Attempt 1')
})

it('renders attempt line correctly with 4 allowed attempts', () => {
  const assignment = mockAssignment({allowedAttempts: 4})
  ReactDOM.render(<Attempt assignment={assignment} />, document.getElementById('fixtures'))
  const attempt_line = $('[data-test-id="attempt"]')
  expect(attempt_line.text()).toEqual('Attempt 1 of 4')
})
