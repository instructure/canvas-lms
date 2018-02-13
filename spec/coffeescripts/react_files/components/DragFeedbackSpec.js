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
  'compiled/models/File'
  'jsx/files/DragFeedback'
], ($, React, ReactDOM, TestUtils, File, DragFeedback) ->

  QUnit.module 'DragFeedback'

  test 'DF: shows a badge with number of items being dragged', ->
    file = new File(id: 1, name: 'Test File', thumbnail_url: 'blah')
    file2 = new File(id: 2, name: 'Test File 2', thumbnail_url: 'blah')

    file.url = -> "some_url"
    file2.url = -> "some_url"
    dragFeedback = TestUtils.renderIntoDocument(React.createElement(DragFeedback, pageX: 1, pageY: 1, itemsToDrag: [file, file2]))

    equal dragFeedback.getDOMNode().getElementsByClassName('badge')[0].innerHTML, "2", "has two items"
    ReactDOM.unmountComponentAtNode(dragFeedback.getDOMNode().parentNode)
