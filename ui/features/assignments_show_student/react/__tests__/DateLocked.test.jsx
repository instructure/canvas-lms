/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import $ from 'jquery'

import DateLocked from '../DateLocked'

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
  ReactDOM.render(<DateLocked date="TEST" type="assignment" />, document.getElementById('fixtures'))
  const element = $('[data-testid="assignments-2-date-locked"]')
  expect(element).toHaveLength(1)
})

it('includes date in lock reason text', () => {
  const {getByText} = render(<DateLocked date="2020-07-04T19:30:00-01:00" type="assignment" />)

  expect(getByText('This assignment is locked until Jul 4, 2020 at 8:30pm.')).toBeInTheDocument()
})
