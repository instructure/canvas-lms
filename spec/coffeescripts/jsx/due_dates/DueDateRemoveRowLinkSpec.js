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
  'jsx/due_dates/DueDateRemoveRowLink'
], ($, React, ReactDOM, {Simulate}, _, DueDateRemoveRowLink) ->

  QUnit.module 'DueDateRemoveRowLink',
    setup: ->
      props =
        handleClick: ->

      @handleClick = @stub(props, 'handleClick')
      DueDateRemoveRowLinkElement = React.createElement(DueDateRemoveRowLink, props)
      @DueDateRemoveRowLink = ReactDOM.render(DueDateRemoveRowLinkElement, $('<div>').appendTo('body')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@DueDateRemoveRowLink.getDOMNode().parentNode)

  test 'renders', ->
    ok @DueDateRemoveRowLink.isMounted()

  test 'calls handleClick prop when clicked', ->
    Simulate.click(@DueDateRemoveRowLink.refs.removeRowIcon.getDOMNode())
    ok @handleClick.calledOnce
