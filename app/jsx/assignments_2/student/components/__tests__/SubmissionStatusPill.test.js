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
  const missingPill = $('[data-test-id="missing-pill"]')
  const latePill = $('[data-test-id="late-pill"]')
  expect(missingPill).toHaveLength(0)
  expect(latePill).toHaveLength(0)
})

it('render late when given late', () => {
  ReactDOM.render(
    <SubmissionStatusPill submissionStatus="late" />,
    document.getElementById('fixtures')
  )
  const latePill = $('[data-test-id="late-pill"]')
  expect(latePill.text()).toEqual('Late')
})

it('renders missing when given missing', () => {
  ReactDOM.render(
    <SubmissionStatusPill submissionStatus="missing" />,
    document.getElementById('fixtures')
  )
  const missingPill = $('[data-test-id="missing-pill"]')
  expect(missingPill.text()).toEqual('Missing')
})
