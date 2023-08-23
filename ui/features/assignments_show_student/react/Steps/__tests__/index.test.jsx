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
import Steps from '../index'
import StepItem from '../StepItem/index'
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

it('should render', () => {
  ReactDOM.render(<Steps />, document.getElementById('fixtures'))
  const element = $('[data-testid="assignment-2-step-index"]')
  expect(element).toHaveLength(1)
})

it('should not render collapsed class when not collapsed', () => {
  ReactDOM.render(<Steps isCollapsed={false} />, document.getElementById('fixtures'))
  const element = $('[data-testid="steps-container-collapsed"]')
  expect(element).toHaveLength(0)
})

it('should render collapsed class when collapsed', () => {
  ReactDOM.render(<Steps isCollapsed={true} />, document.getElementById('fixtures'))
  const element = $('[data-testid="steps-container-collapsed"]')
  expect(element).toHaveLength(1)
})

it('should render with StepItems', () => {
  ReactDOM.render(
    <Steps label="Settings">
      <StepItem label="Phase one" status="complete" />
      <StepItem label="Phase two" status="in-progress" />
      <StepItem label="Phase three" />
    </Steps>,
    document.getElementById('fixtures')
  )
  const element = $('li')
  expect(element).toHaveLength(3)
})

it('should render aria-current for the item that is in progress', () => {
  ReactDOM.render(
    <Steps label="Settings">
      <StepItem label="Phase one" status="complete" />
      <StepItem label="Phase two" status="in-progress" />
      <StepItem label="Phase three" />
    </Steps>,
    document.getElementById('fixtures')
  )

  const items = $('li')
  expect(items[0].getAttribute('aria-current')).toEqual('false')
  expect(items[1].getAttribute('aria-current')).toEqual('true')
  expect(items[2].getAttribute('aria-current')).toEqual('false')
})
