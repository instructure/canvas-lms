/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import MockDate from 'mockdate'
import EmptyDays from '../index'

const TZ = 'Asia/Tokyo'

const getDefaultProps = (overrides = {}) => {
  return {
    day: '2017-04-23',
    endday: '2017-04-26',
    animatableIndex: 0,
    timeZone: TZ,
    registerAnimatable: () => {},
    deregisterAnimatable: () => {},
    ...overrides,
  }
}

describe('EmptyDays', () => {
  beforeAll(() => {
    MockDate.set('2017-04-22', TZ)
  })

  afterAll(() => {
    MockDate.reset()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the date range and empty state message', () => {
    const {getByText} = render(<EmptyDays {...getDefaultProps()} />)

    // Check that the date range is displayed correctly
    expect(getByText('April 23 to April 26')).toBeInTheDocument()

    // Check that the empty state message is displayed
    expect(getByText('Nothing Planned Yet')).toBeInTheDocument()
  })

  it('applies the today class when date range includes today', () => {
    const {container} = render(<EmptyDays {...getDefaultProps({day: '2017-04-22'})} />)

    // Check that the today class is applied when the date range includes today
    const emptyDaysElement = container.querySelector('.planner-empty-days')
    expect(emptyDaysElement).toHaveClass('planner-today')
  })

  it('does not apply the today class when date range does not include today', () => {
    const {container} = render(<EmptyDays {...getDefaultProps({day: '2017-04-23'})} />)

    // Check that the today class is not applied when the date range doesn't include today
    const emptyDaysElement = container.querySelector('.planner-empty-days')
    expect(emptyDaysElement).not.toHaveClass('planner-today')
  })

  it('renders the date range in the correct format', () => {
    const {getByText} = render(
      <EmptyDays {...getDefaultProps({day: '2017-05-01', endday: '2017-05-05'})} />,
    )

    // Check that the date range is formatted correctly
    expect(getByText('May 1 to May 5')).toBeInTheDocument()
  })
})
