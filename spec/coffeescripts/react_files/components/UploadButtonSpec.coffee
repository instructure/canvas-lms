#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'jsx/files/UploadButton'
  'compiled/react_files/modules/FileOptionsCollection'
], (React, ReactDOM, {Simulate}, $, UploadButton, FileOptionsCollection) ->

  QUnit.module 'UploadButton',
    setup: ->
      props =
        currentFolder:
          files:
            models: []

      @button = ReactDOM.render(React.createElement(UploadButton, props), $('<div>').appendTo("#fixtures")[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@button.getDOMNode().parentNode)
      $("#fixtures").empty()

  test 'hides actual file input form', ->
    form = @button.refs.form.getDOMNode()
    ok $(form).attr('class').match(/hidden/), 'is hidden from user'

  test 'only enques uploads when state.newUploads is true', ->
    @spy(@button, 'queueUploads')

    @button.state.nameCollisions.length = 0
    @button.state.resolvedNames.length = 1

    FileOptionsCollection.state.newOptions = false
    @button.componentDidUpdate()
    equal @button.queueUploads.callCount, 0

    FileOptionsCollection.state.newOptions = true
    @button.componentDidUpdate()
    equal @button.queueUploads.callCount, 1
