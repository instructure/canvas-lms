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
  'react'
  'react-dom'
  'react-addons-test-utils'
  'underscore'
  'jsx/dashboard_card/DashboardCardBox'
  'jsx/dashboard_card/CourseActivitySummaryStore'
], (React, ReactDOM, TestUtils, _, DashboardCardBox, CourseActivitySummaryStore) ->

  QUnit.module 'DashboardCardBox',
    setup: ->
      @stub(CourseActivitySummaryStore, 'getStateForCourse').returns({})
      @courseCards = [{
        id: 1,
        shortName: 'Bio 101'
      }, {
        id: 2,
        shortName: 'Philosophy 201'
      }]

    teardown: ->
      localStorage.clear()
      if @component
        ReactDOM.unmountComponentAtNode(@component.getDOMNode().parentNode)

  test 'should render div.ic-DashboardCard per provided courseCard', ->
    CardBox = React.createElement(DashboardCardBox, {
      courseCards: @courseCards
    })
    @component = TestUtils.renderIntoDocument(CardBox)
    $html = $(@component.getDOMNode())
    equal $html.children('div.ic-DashboardCard').length, @courseCards.length
