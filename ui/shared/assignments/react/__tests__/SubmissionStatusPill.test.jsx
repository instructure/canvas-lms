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

import SubmissionStatusPill from '../SubmissionStatusPill'

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

it('does not render with null status', () => {
  ReactDOM.render(<SubmissionStatusPill />, document.getElementById('fixtures'))
  const excusedPill = $('[data-testid="excused-pill"]')
  const missingPill = $('[data-testid="missing-pill"]')
  const latePill = $('[data-testid="late-pill"]')
  expect(excusedPill).toHaveLength(0)
  expect(missingPill).toHaveLength(0)
  expect(latePill).toHaveLength(0)
})

it('renders excused when given excused only', () => {
  ReactDOM.render(<SubmissionStatusPill excused={true} />, document.getElementById('fixtures'))
  const excusedPill = $('[data-testid="excused-pill"]')
  expect(excusedPill.text()).toEqual('Excused')
})

it('renders only excused even when submission is also missing', () => {
  ReactDOM.render(
    <SubmissionStatusPill excused={true} submissionStatus="missing" />,
    document.getElementById('fixtures')
  )
  const excusedPill = $('[data-testid="excused-pill"]')
  expect(excusedPill.text()).toEqual('Excused')
  const missingPill = $('[data-testid="missing-pill"]')
  expect(missingPill).toHaveLength(0)
})

it('renders only excused even when submission is also late', () => {
  ReactDOM.render(
    <SubmissionStatusPill excused={true} submissionStatus="late" />,
    document.getElementById('fixtures')
  )
  const excusedPill = $('[data-testid="excused-pill"]')
  expect(excusedPill.text()).toEqual('Excused')
  const latePill = $('[data-testid="late-pill"]')
  expect(latePill).toHaveLength(0)
})

it('renders late when given late', () => {
  ReactDOM.render(
    <SubmissionStatusPill submissionStatus="late" />,
    document.getElementById('fixtures')
  )
  const latePill = $('[data-testid="late-pill"]')
  expect(latePill.text()).toEqual('Late')
  const excusedPill = $('[data-testid="excused-pill"]')
  expect(excusedPill).toHaveLength(0)
})

it('renders missing when given missing', () => {
  ReactDOM.render(
    <SubmissionStatusPill submissionStatus="missing" />,
    document.getElementById('fixtures')
  )
  const missingPill = $('[data-testid="missing-pill"]')
  expect(missingPill.text()).toEqual('Missing')
  const excusedPill = $('[data-testid="excused-pill"]')
  expect(excusedPill).toHaveLength(0)
})
