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

import StudentDateTitle from '../StudentDateTitle'

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
jest.mock('timezone')

it('renders title correctly', () => {
  ReactDOM.render(
    <StudentDateTitle title="Egypt Economy Research" dueDate={new Date('12/28/2018 23:59:00')} />,
    document.getElementById('fixtures')
  )
  const title = $('[data-test-id="title"]')
  expect(title.text()).toEqual('Egypt Economy Research')
})

it('renders date correctly', () => {
  ReactDOM.render(
    <StudentDateTitle title="Egypt Economy Research" dueDate={new Date('12/28/2018 23:59:00')} />,
    document.getElementById('fixtures')
  )
  const title = $('[data-test-id="due-date-display"]')
  // Reason why this is showing up twice is once for screenreader content and again for regular content
  expect(title.text()).toEqual('Due: 12/28/2018 23:59:00Due: 12/28/2018 23:59:002018-12-28')
})
