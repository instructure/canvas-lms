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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import DueDateCalendars from 'jsx/due_dates/DueDateCalendars'
import fakeENV from 'helpers/fakeENV'

let wrapper = null

QUnit.module('DueDateCalendars', {
  setup() {
    wrapper = $('<div>').appendTo('body')[0]
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    this.someDate = new Date(Date.UTC(2012, 1, 1, 7, 0, 0))
    const props = {
      replaceDate() {},
      rowKey: 'nullnullnull',
      dates: {due_at: this.someDate},
      overrides: [
        {
          get() {},
          set() {}
        }
      ],
      sections: {},
      dateValue: this.someDate
    }
    const DueDateCalendarsElement = <DueDateCalendars {...props} />
    this.dueDateCalendars = ReactDOM.render(DueDateCalendarsElement, wrapper)
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dueDateCalendars).parentNode)
    return wrapper.remove()
  }
})

test('renders', function() {
  ok(this.dueDateCalendars)
})

test('can get the date for a datetype', function() {
  equal(this.dueDateCalendars.props.dates.due_at, this.someDate)
})
