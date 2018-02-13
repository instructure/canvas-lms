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
  'jsx/files/CurrentUploads'
  'compiled/react_files/modules/FileUploader'
  'compiled/react_files/modules/UploadQueue'
], (React, ReactDOM, $, CurrentUploads, FileUploader, UploadQueue) ->

  QUnit.module 'CurrentUploads',
    setup: ->
      @uploads = ReactDOM.render(React.createElement(CurrentUploads), $('<div>').appendTo('#fixtures')[0])

    teardown: ->
      ReactDOM.unmountComponentAtNode(@uploads.getDOMNode().parentNode)
      $("#fixtures").empty()

    mockUploader: (name, progress) ->
      uploader = new FileUploader({file: {}})
      @stub(uploader, 'getFileName').returns(name)
      @stub(uploader, 'roundProgress').returns(progress)
      uploader

  test 'pulls FileUploaders from UploadQueue', ->
    allUploads = [@mockUploader('name', 0), @mockUploader('other', 0)]
    @stub(UploadQueue, 'getAllUploaders').returns(allUploads)

    UploadQueue.onChange()
    equal @uploads.state.currentUploads, allUploads
