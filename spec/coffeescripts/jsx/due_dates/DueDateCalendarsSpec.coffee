#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/due_dates/DueDateCalendars'
  'helpers/fakeENV'
], ($, React, ReactDOM, {Simulate, SimulateNative}, _, DueDateCalendars, fakeENV) ->
  wrapper = null

  QUnit.module 'DueDateCalendars',
    setup: ->
      wrapper = $('<div>').appendTo('body')[0]
      fakeENV.setup()
      ENV.context_asset_string = "course_1"
      @someDate = new Date(Date.UTC(2012, 1, 1, 7, 0, 0))
      props =
        replaceDate: ->
        rowKey: "nullnullnull"
        dates: {due_at: @someDate}
        overrides: [{get: (->), set:(->)}]
        sections: {}
        dateValue: @someDate

      DueDateCalendarsElement = React.createElement(DueDateCalendars, props)
      @dueDateCalendars = ReactDOM.render(DueDateCalendarsElement, wrapper)

    teardown: ->
      fakeENV.teardown()
      ReactDOM.unmountComponentAtNode(@dueDateCalendars.getDOMNode().parentNode)
      wrapper.remove()

  test 'renders', ->
    ok @dueDateCalendars.isMounted()

  test 'can get the date for a datetype', ->
    equal @dueDateCalendars.props.dates["due_at"], @someDate
