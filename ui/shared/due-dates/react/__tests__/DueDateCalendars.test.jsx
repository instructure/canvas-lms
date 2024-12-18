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
import DueDateCalendars from '../DueDateCalendars'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('DueDateCalendars', () => {
  const someDate = new Date(Date.UTC(2012, 1, 1, 7, 0, 0))
  const defaultProps = {
    replaceDate: jest.fn(),
    rowKey: 'nullnullnull',
    dates: {
      due_at: someDate,
    },
    overrides: [
      {
        get: jest.fn(),
        set: jest.fn(),
      },
    ],
    sections: {},
    dateValue: someDate,
    disabled: false,
    dueDatesReadonly: false,
    availabilityDatesReadonly: false,
  }

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders successfully', () => {
    const {container} = render(<DueDateCalendars {...defaultProps} />)
    expect(container).toBeTruthy()
  })

  it('has correct date for datetype', () => {
    const {rerender} = render(<DueDateCalendars {...defaultProps} />)
    expect(defaultProps.dates.due_at).toEqual(someDate)
  })
})
