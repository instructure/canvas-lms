/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import DatetimeDisplay from '@canvas/datetime/react/components/DatetimeDisplay'
import * as tz from '@canvas/datetime'

QUnit.module('DatetimeDisplay')

test('renders the formatted datetime using the provided format', () => {
  const datetime = new Date().toString()
  const wrapper = shallow(<DatetimeDisplay datetime={datetime} format="%b" />)
  const formattedTime = wrapper.find('.DatetimeDisplay').text()
  equal(formattedTime, tz.format(datetime, '%b'))
})

test('works with a date object', () => {
  const date = new Date(0)
  const wrapper = shallow(<DatetimeDisplay datetime={date} format="%b" />)
  const formattedTime = wrapper.find('.DatetimeDisplay').text()
  equal(formattedTime, tz.format(date.toString(), '%b'))
})

test('has a default format when none is provided', () => {
  const date = new Date(0).toString()
  const wrapper = shallow(<DatetimeDisplay datetime={date} />)
  const formattedTime = wrapper.find('.DatetimeDisplay').text()
  equal(formattedTime, tz.format(date, '%c'))
})
