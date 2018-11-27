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
import StepItem from '../index'
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

it('should render', async () => {
  ReactDOM.render(<StepItem label={() => {}} />, document.getElementById('fixtures'))
  const component = $('.step-item-step')
  expect(component).toHaveLength(1)
})

it('should render complete status', async () => {
  ReactDOM.render(
    <StepItem status="complete" label="Test label" />,
    document.getElementById('fixtures')
  )
  const component = $('.step-item-step')
  expect(component.hasClass('complete')).toBeTruthy()
})

it('should render in-progress status', async () => {
  ReactDOM.render(
    <StepItem status="in-progress" label="Test label" />,
    document.getElementById('fixtures')
  )
  const component = $('.step-item-step')
  expect(component.hasClass('in-progress')).toBeTruthy()
})

it('should render unavailable status', async () => {
  ReactDOM.render(
    <StepItem status="unavailable" label="Test label" />,
    document.getElementById('fixtures')
  )
  const component = $('.step-item-step')
  expect(component.hasClass('unavailable')).toBeTruthy()
})

it('should render label correctly', async () => {
  ReactDOM.render(
    <StepItem status="complete" label={status => `progress 2 ${status}`} />,
    document.getElementById('fixtures')
  )
  const component = $('.step-item-step')
  expect(component.text()).toEqual('progress 2 complete')
})
