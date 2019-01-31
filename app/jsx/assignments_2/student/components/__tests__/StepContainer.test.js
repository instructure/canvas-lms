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
import StepContainer from '../StepContainer'

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

it('will render the availaible step container if assignment is not locked', () => {
  const assignment = mockAssignment({lockInfo: {isLocked: false}})
  ReactDOM.render(<StepContainer assignment={assignment} />, document.getElementById('fixtures'))

  const expectedElement = $('.in-progress')
  const unexpectedElement = $('.unavailable')
  expect(expectedElement).toHaveLength(1)
  expect(unexpectedElement).toHaveLength(0)
})

it('will render the unavailaible step container if assignment is locked', () => {
  const assignment = mockAssignment({lockInfo: {isLocked: true}})
  ReactDOM.render(<StepContainer assignment={assignment} />, document.getElementById('fixtures'))

  const expectedElement = $('.unavailable')
  const unexpectedElement = $('.in-progress')
  expect(expectedElement).toHaveLength(1)
  expect(unexpectedElement).toHaveLength(0)
})

it('will render collapsed label if steps is collapsed', () => {
  const label = 'TEST'
  const assignment = mockAssignment({lockInfo: {isLocked: false}})
  ReactDOM.render(
    <StepContainer assignment={assignment} isCollapsed collapsedLabel={label} />,
    document.getElementById('fixtures')
  )

  const expectedElement = $('.steps-main-status-label')
  expect(expectedElement.text()).toBe(label)
})

it('will not render collapsed label if steps is collapsed', () => {
  const label = 'TEST'
  const assignment = mockAssignment({lockInfo: {isLocked: false}})
  ReactDOM.render(
    <StepContainer assignment={assignment} isCollapsed={false} collapsedLabel={label} />,
    document.getElementById('fixtures')
  )

  const expectedElement = $('.steps-main-status-label')
  expect(expectedElement.text()).toHaveLength(0)
})
