/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import CurrentUploads from 'jsx/files/CurrentUploads'
import FileUploader from 'compiled/react_files/modules/FileUploader'
import UploadQueue from 'compiled/react_files/modules/UploadQueue'

QUnit.module('CurrentUploads', {
  setup() {
    this.uploads = ReactDOM.render(<CurrentUploads />, $('<div>').appendTo('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.uploads.getDOMNode().parentNode)
    $('#fixtures').empty()
  },
  mockUploader(name, progress) {
    const uploader = new FileUploader({file: {}})
    this.stub(uploader, 'getFileName').returns(name)
    this.stub(uploader, 'roundProgress').returns(progress)
    return uploader
  }
})

test('pulls FileUploaders from UploadQueue', function() {
  const allUploads = [this.mockUploader('name', 0), this.mockUploader('other', 0)]
  this.stub(UploadQueue, 'getAllUploaders').returns(allUploads)
  UploadQueue.onChange()
  equal(this.uploads.state.currentUploads, allUploads)
})
