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
import AvailabilityDates from '../AvailabilityDates'
import {mockAssignment} from '../../graphql/studentMocks'
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

it('renders nothing if lockAt and unlockAt are null', async () => {
  const assignment = await mockAssignment()
  ReactDOM.render(
    <AvailabilityDates assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const element = $('#fixtures')
  expect(element.text()).toEqual('')
})

it('renders correctly if lockAt is set and and unlockAt is null', async () => {
  const assignment = await mockAssignment({Assignment: {lockAt: '2016-07-11T23:00:00-00:00'}})
  ReactDOM.render(
    <AvailabilityDates assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const element = $('#fixtures')

  // Rendered twice cause one of them is a screenreader only
  const expected =
    'Available until Jul 11, 2016 11:00pmAvailable until Jul 11, 2016 11:00pm7/11/2016'
  expect(element.text()).toEqual(expected)
})

it('renders correctly if unlockAt is set and and lockAt is null', async () => {
  const assignment = await mockAssignment({Assignment: {unlockAt: '2016-07-11T23:00:00-00:00'}})
  ReactDOM.render(
    <AvailabilityDates assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const element = $('#fixtures')

  // Rendered twice cause one of them is a screenreader only
  const expected =
    'Available after Jul 11, 2016 11:00pmAvailable after Jul 11, 2016 11:00pm7/11/2016'
  expect(element.text()).toEqual(expected)
})

it('renders correctly if unlockAt and lockAt are set', async () => {
  const assignment = await mockAssignment({
    Assignment: {unlockAt: '2016-07-11T23:00:00-00:00', lockAt: '2016-07-15T23:00:00-00:00'},
  })
  ReactDOM.render(
    <AvailabilityDates assignment={assignment} />,
    document.getElementById('fixtures')
  )
  const element = $('#fixtures')

  // Rendered twice cause one of them is a screenreader only
  const expected =
    'Available: Jul 11, 2016 11:00pm until Jul 15, 2016 11:00pmAvailable: Jul 11, 2016 11:00pm until Jul 15, 2016 11:00pm7/11/2016 to 7/15/2016'
  expect(element.text()).toEqual(expected)
})

it('renders correctly if unlockAt and lockAt are set and rendered in short mode', async () => {
  const assignment = await mockAssignment({
    Assignment: {unlockAt: '2016-07-11T23:00:00-00:00', lockAt: '2016-07-15T23:00:00-00:00'},
  })
  ReactDOM.render(
    <AvailabilityDates assignment={assignment} formatStyle="short" />,
    document.getElementById('fixtures')
  )
  const element = $('#fixtures')

  // Rendered twice cause one of them is a screenreader only
  const expected = 'Jul 11 to Jul 15Jul 11 to Jul 157/11/2016 to 7/15/2016'
  expect(element.text()).toEqual(expected)
})
