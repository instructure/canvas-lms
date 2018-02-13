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
  'underscore',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/epub_exports/CourseListItem'
], (_, React, ReactDOM, TestUtils, CourseListItem, I18n) ->

  QUnit.module 'CourseListItemSpec',
    setup: ->
      @props = {
        course: {
          name: 'Maths 101',
          id: 1
        }
      }

  test 'getDisplayState', ->
    CourseListItemElement = React.createElement(CourseListItem, @props)
    component = TestUtils.renderIntoDocument(CourseListItemElement)
    ok _.isNull(component.getDisplayState()),
      'display state should be null without epub_export'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

    @props.course = {
      epub_export: {
        permissions: {},
        workflow_state: 'generating'
      }
    }
    CourseListItemElement = React.createElement(CourseListItem, @props)
    component = TestUtils.renderIntoDocument(CourseListItemElement)
    ok !_.isNull(component.getDisplayState()),
      'display state should not be null with epub_export'
    ok component.getDisplayState().match('Generating'), 'should include workflow_state'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'render', ->
    CourseListItemElement = React.createElement(CourseListItem, @props)
    component = TestUtils.renderIntoDocument(CourseListItemElement)
    ok !_.isNull(component.getDOMNode()), 'should render with course'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
