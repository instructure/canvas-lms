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
  'jsx/files/DialogPreview'
  'jsx/files/FilesystemObjectThumbnail'
], ($, React, ReactDOM, TestUtils, File, DialogPreview, FilesystemObjectThumbnail) ->

  QUnit.module 'DialogPreview',
    setup: ->
    teardown: ->

  test 'DP: single item rendered with FilesystemObjectThumbnail', ->
    file = new File(name: 'Test File', thumbnail_url: 'blah')
    file.url = -> "some_url"
    fsObjStub = @stub(FilesystemObjectThumbnail.prototype, 'render').returns(React.createElement('div'))
    dialogPreview = TestUtils.renderIntoDocument(React.createElement(DialogPreview, itemsToShow: [file]))

    ok fsObjStub.calledOnce
    ReactDOM.unmountComponentAtNode(dialogPreview.getDOMNode().parentNode)

  test 'DP: multiple file items rendered in i elements', ->
    url = -> "some_url"
    file = new File(name: 'Test File', thumbnail_url: 'blah')
    file2 = new File(name: 'Test File', thumbnail_url: 'blah')

    file.url = url
    file2.url = url

    dialogPreview = TestUtils.renderIntoDocument(React.createElement(DialogPreview, itemsToShow: [file, file2]))

    equal dialogPreview.getDOMNode().getElementsByTagName('i').length, 2, "there are two files rendered"

    ReactDOM.unmountComponentAtNode(dialogPreview.getDOMNode().parentNode)
