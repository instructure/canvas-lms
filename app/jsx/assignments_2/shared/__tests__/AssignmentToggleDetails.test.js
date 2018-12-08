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
import AssignmentToggleDetails from '../AssignmentToggleDetails'
import $ from 'jquery'

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

it('renders normally', () => {
  const assignment = {
    name: 'an assignment',
    pointsPossible: 42,
    dueAt: 'some time',
    description: 'an assignment'
  }
  ReactDOM.render(
    <AssignmentToggleDetails description={assignment.description} />,
    document.getElementById('fixtures')
  )
  const toggler = $('[data-test-id="assignments-2-assignment-toggle-details"]')
  toggler.click()
  const element = $('[data-test-id="assignments-2-assignment-toggle-details-text"]')
  expect(element.text()).toEqual(assignment.description)
})
