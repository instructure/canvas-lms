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
import Header from '../Header'

beforeAll(() => {
  const found = document.getElementById('fixtures')
  if (!found) {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)
  }
  window.pageYOffset = 0
})

afterEach(() => {
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

it('renders normally', () => {
  ReactDOM.render(
    <Header scrollThreshold={150} assignment={mockAssignment()} />,
    document.getElementById('fixtures')
  )
  const element = $('[data-test-id="assignments-2-student-header"]')
  expect(element).toHaveLength(1)
})

it('dispatches scroll event properly when less than threshold', () => {
  ReactDOM.render(
    <Header scrollThreshold={150} assignment={mockAssignment()} />,
    document.getElementById('fixtures')
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 100
  window.dispatchEvent(scrollEvent)
  const foundClassElement = $('[data-test-id="assignment-student-header-normal"]')
  expect(foundClassElement).toHaveLength(1)
})

it('dispatches scroll event properly when greather than threshold', () => {
  ReactDOM.render(
    <Header scrollThreshold={150} assignment={mockAssignment()} />,
    document.getElementById('fixtures')
  )
  const scrollEvent = new Event('scroll')
  window.pageYOffset = 500
  window.dispatchEvent(scrollEvent)
  const foundClassElement = $('[data-test-id="assignment-student-header-sticky"]')
  expect(foundClassElement).toHaveLength(1)
})
