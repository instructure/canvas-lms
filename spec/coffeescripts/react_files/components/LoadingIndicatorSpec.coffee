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
  'jquery'
  'jsx/files/LoadingIndicator'
], (React, ReactDOM, TestUtils, $, LoadingIndicator) ->

  QUnit.module 'LoadingIndicator'

  test 'display none if no props supplied', ->
    loadingIndicator = React.createFactory(LoadingIndicator)
    rendered = TestUtils.renderIntoDocument(loadingIndicator())
    equal $(rendered.getDOMNode()).css('display'), "none", "loading indicator not shown"
    ReactDOM.unmountComponentAtNode(rendered.getDOMNode().parentNode)

  test 'if props supplied for loading', ->
    loadingIndicator = React.createFactory(LoadingIndicator)
    rendered = TestUtils.renderIntoDocument(loadingIndicator(isLoading: true))
    equal $(rendered.getDOMNode()).css('display'), "", "loading indicator is shown"
    ReactDOM.unmountComponentAtNode(rendered.getDOMNode().parentNode)
