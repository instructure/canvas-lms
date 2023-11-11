/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import TimeZoneSelect from '../TimeZoneSelect'
import {render} from '@testing-library/react'
import isEqual from 'lodash/isEqual'

let liveRegion = null
beforeAll(() => {
  if (!document.getElementById('flash_screenreader_holder')) {
    liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  }
})

afterAll(() => {
  if (liveRegion) {
    liveRegion.remove()
  }
})

const timezones = [
  {
    name: 'Central',
    localized_name: 'Central localized',
  },
  {
    name: 'Eastern',
    localized_name: 'Eastern localized',
  },
  {
    name: 'Mountain',
    localized_name: 'Mountain localized',
  },
  {
    name: 'Pacific',
    localized_name: 'Pacific localized',
  },
]
const priorityZones = [timezones[0]]

describe('TimeZoneSelect', () => {
  it('renders the value', () => {
    const {getByDisplayValue} = render(
      <TimeZoneSelect
        label="the label"
        onChange={() => {}}
        value="Mountain"
        timezones={timezones}
        priority_zones={priorityZones}
      />
    )

    expect(getByDisplayValue('Mountain localized')).toBeInTheDocument()
  })

  it('renders the right zone options', () => {
    const {getByText} = render(
      <TimeZoneSelect
        label="the label"
        onChange={() => {}}
        value="Mountain"
        timezones={timezones}
        priority_zones={priorityZones}
      />
    )

    // open the select dropdown
    const label = getByText('the label')
    label.click()

    const priorityOptions = document.querySelectorAll(
      '[data-testid="Group:Common Timezones"] span[role="option"]'
    )
    isEqual(
      Array.from(priorityOptions).map(e => ({
        name: e.getAttribute('value'),
        localized_name: e.textContent,
      })),
      priorityZones
    )

    const allOptions = document.querySelectorAll(
      '[data-testid="Group:All Timezones"] span[role="option"]'
    )
    isEqual(
      Array.from(allOptions).map(e => ({
        name: e.getAttribute('value'),
        localized_name: e.textContent,
      })),
      timezones
    )
  })

  it('calls onChange on a selection', () => {
    const onChangeTZ = jest.fn()
    const {getByText} = render(
      <TimeZoneSelect
        label="the label"
        onChange={onChangeTZ}
        timezones={timezones}
        priority_zones={priorityZones}
      />
    )

    // open the select dropdown
    const label = getByText('the label')
    label.click()

    const eastern = getByText('Eastern localized')
    eastern.click()

    // onChange's event.target.value === onChanges's 2nd argument
    expect(onChangeTZ).toHaveBeenCalled()
    expect(onChangeTZ.mock.calls[0][0].target.value).toEqual('Eastern')
    expect(onChangeTZ.mock.calls[0][1]).toEqual('Eastern')
  })
})
