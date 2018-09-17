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
import {Simulate} from 'react-addons-test-utils'
import $ from 'jquery'
import UploadButton from 'jsx/files/UploadButton'
import FileOptionsCollection from 'compiled/react_files/modules/FileOptionsCollection'

QUnit.module('UploadButton', {
  setup() {
    const props = {currentFolder: {files: {models: []}}}
    this.button = ReactDOM.render(<UploadButton {...props} />, $('<div>').appendTo('#fixtures')[0])
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.button).parentNode)
    $('#fixtures').empty()
  }
})

test('hides actual file input form', function() {
  const form = this.button.refs.form
  ok(
    $(form)
      .attr('class')
      .match(/hidden/),
    'is hidden from user'
  )
})

test('only enques uploads when state.newUploads is true', function() {
  sandbox.spy(this.button, 'queueUploads')
  this.button.state.nameCollisions.length = 0
  this.button.state.resolvedNames.length = 1
  FileOptionsCollection.state.newOptions = false
  this.button.componentDidUpdate()
  equal(this.button.queueUploads.callCount, 0)
  FileOptionsCollection.state.newOptions = true
  this.button.componentDidUpdate()
  equal(this.button.queueUploads.callCount, 1)
})
