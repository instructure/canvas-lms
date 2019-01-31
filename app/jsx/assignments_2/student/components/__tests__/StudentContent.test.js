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
import StudentContent from '../StudentContent'

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

it('renders the student header if the assignment is unlocked', () => {
  const assignment = mockAssignment({lockInfo: {isLocked: false}})
  ReactDOM.render(<StudentContent assignment={assignment} />, document.getElementById('fixtures'))
  const element = $('[data-test-id="assignments-2-student-header"]')
  expect(element).toHaveLength(1)
})

it('renders the student header if the assignment is locked', () => {
  const assignment = mockAssignment({lockInfo: {isLocked: true}})
  ReactDOM.render(<StudentContent assignment={assignment} />, document.getElementById('fixtures'))
  const element = $('[data-test-id="assignments-2-student-header"]')
  expect(element).toHaveLength(1)
})

it('renders the assignment details and student content tab if the assignment is unlocked', () => {
  const assignment = mockAssignment({lockInfo: {isLocked: false}})
  ReactDOM.render(<StudentContent assignment={assignment} />, document.getElementById('fixtures'))

  const contentTabs = $('[data-test-id="assignment-2-student-content-tabs"]')
  const toggleDetails = $('.a2-toggle-details-container')
  const root = $('#fixtures')
  expect(toggleDetails).toHaveLength(1)
  expect(contentTabs).toHaveLength(1)
  expect(root.text()).not.toMatch('Availability Dates')
})

it('renders the availability dates if the assignment is locked', () => {
  const assignment = mockAssignment({lockInfo: {isLocked: true}})
  ReactDOM.render(<StudentContent assignment={assignment} />, document.getElementById('fixtures'))

  const contentTabs = $('[data-test-id="assignment-2-student-content-tabs"]')
  const toggleDetails = $('.a2-toggle-details-container')
  const root = $('#fixtures')
  expect(toggleDetails).toHaveLength(0)
  expect(contentTabs).toHaveLength(0)
  expect(root.text()).toMatch('Availability Dates')
})
