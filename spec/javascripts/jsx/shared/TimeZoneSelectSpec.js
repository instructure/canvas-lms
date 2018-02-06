/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import TimeZoneSelect from 'jsx/shared/components/TimeZoneSelect'

QUnit.module('TimeZoneSelect')

test('renders the right zones', () => {
  const timezones = [
    {
      name: 'Central',
      localized_name: 'Central localized'
    },
    {
      name: 'Eastern',
      localized_name: 'Eastern localized'
    },
    {
      name: 'Mountain',
      localized_name: 'Mountain localized'
    },
    {
      name: 'Pacific',
      localized_name: 'Pacific localized'
    }
  ]
  const priorityZones = [timezones[0]]

  const wrapper = shallow(<TimeZoneSelect timezones={timezones} priority_zones={priorityZones} />)

  const prorityOptions = wrapper.find('optgroup[label="Common Timezones"] option')
  deepEqual(
    prorityOptions.map(e => ({name: e.prop('value'), localized_name: e.text()})),
    priorityZones
  )

  const allOptions = wrapper.find('optgroup[label="All Timezones"] option')
  deepEqual(
    allOptions.map(e => ({name: e.prop('value'), localized_name: e.text()})),
    timezones
  )
})
