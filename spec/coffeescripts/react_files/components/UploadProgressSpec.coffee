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
  'jquery'
  'jsx/files/UploadProgress'
  'compiled/react_files/modules/FileUploader'
], (React, ReactDOM, $, UploadProgress, FileUploader) ->

  QUnit.module 'UploadProgress',
    setup: ->
      ProgressContainer = React.createClass
        getInitialState: ->
          uploader: @props.uploader

        render: ->
          React.createElement(UploadProgress, ref: 'prog', uploader: @state.uploader)

      @uploader = @mockUploader('filename', 35)
      @node = $('<div>').appendTo('#fixtures')[0]
      @progressContainer = ReactDOM.render(React.createFactory(ProgressContainer)(uploader: @uploader), @node)
      @prog = @progressContainer.refs.prog

    teardown: ->
      ReactDOM.unmountComponentAtNode(@progressContainer.getDOMNode().parentNode)
      $("#fixtures").empty()

    mockUploader: (name, progress) ->
      uploader = new FileUploader({file: {}})
      @stub(uploader, 'getFileName').returns(name)
      @stub(uploader, 'roundProgress').returns(progress)
      uploader

  test 'getLabel displays file name', ->
    equal(@prog.refs.fileName.getDOMNode().textContent, 'filename')

  test 'announces upload progress to screen reader when queue changes', ->
    @stub($, 'screenReaderFlashMessage')
    equal(@prog.props.uploader.roundProgress(), 35)

    # File upload 75% complete
    @progressContainer.setState {uploader: @mockUploader('filename', 75)}
    equal(@prog.props.uploader.roundProgress(), 75)
    equal($.screenReaderFlashMessage.calledWith('filename - 75 percent uploaded'), true)

    # File upload complete
    @progressContainer.setState {uploader: @mockUploader('filename', 100)}
    equal(@prog.props.uploader.roundProgress(), 100)
    equal($.screenReaderFlashMessage.calledWith('filename uploaded successfully!'), true)

  test 'does not announce upload progress to screen reader if progress has not changed', ->
    @stub($, 'screenReaderFlashMessage')
    equal(@prog.props.uploader.roundProgress(), 35)

    # Simulates a "componentWillReceiveProps"
    @progressContainer.setState {uploader: @mockUploader('filename', 35)}
    @progressContainer.setState {uploader: @mockUploader('filename', 35)}
    equal(@prog.props.uploader.roundProgress(), 35)
    equal($.screenReaderFlashMessage.calledOnce, true)
