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
  'react-addons-test-utils'
  'jsx/epub_exports/App',
  'jsx/epub_exports/CourseStore'
], (_, React, ReactDOM, TestUtils, App, CourseEpubExportStore) ->

  QUnit.module 'AppSpec',
    setup: ->
      @props = {
        1: {
          name: 'Maths 101',
          id: 1
        },
        2: {
          name: 'Physics 101',
          id: 2
        }
      }
      sinon.stub(CourseEpubExportStore, 'getAll').returns(true)

    teardown: ->
      CourseEpubExportStore.getAll.restore()

  test 'handeCourseStoreChange', ->
    AppElement = React.createElement(App)
    component = TestUtils.renderIntoDocument(AppElement)
    ok _.isEmpty(component.state), 'precondition'

    CourseEpubExportStore.setState(@props)
    deepEqual component.state, CourseEpubExportStore.getState(),
      'CourseEpubExportStore.setState should trigger component setState'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

