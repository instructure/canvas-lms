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

define(
  ['react', 'react-addons-test-utils', 'jsx/shared/DatetimeDisplay', 'timezone'],
  (React, TestUtils, DatetimeDisplay, tz) => {
    QUnit.module('DatetimeDisplay')

    test('renders the formatted datetime using the provided format', () => {
      let datetime = new Date().toString()
      let component = TestUtils.renderIntoDocument(
        <DatetimeDisplay datetime={datetime} format="%b" />
      )
      let formattedTime = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'DatetimeDisplay'
      ).getDOMNode().innerText
      equal(formattedTime, tz.format(datetime, '%b'))
    })

    test('works with a date object', () => {
      let date = new Date(0)
      let component = TestUtils.renderIntoDocument(<DatetimeDisplay datetime={date} format="%b" />)
      let formattedTime = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'DatetimeDisplay'
      ).getDOMNode().innerText
      equal(formattedTime, tz.format(date.toString(), '%b'))
    })

    test('has a default format when none is provided', () => {
      let date = new Date(0).toString()
      let component = TestUtils.renderIntoDocument(<DatetimeDisplay datetime={date} />)
      let formattedTime = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'DatetimeDisplay'
      ).getDOMNode().innerText
      equal(formattedTime, tz.format(date, '%c'))
    })
  }
)
