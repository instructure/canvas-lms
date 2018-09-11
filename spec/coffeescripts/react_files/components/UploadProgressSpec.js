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
import UploadProgress from 'jsx/files/UploadProgress'
import FileUploader from 'compiled/react_files/modules/FileUploader'

QUnit.module('UploadProgress', {
  setup() {
    class ProgressContainer extends React.Component {
      state = {uploader: this.props.uploader};

      render() {
        return <UploadProgress ref="prog" uploader={this.state.uploader} />
      }
    }

    this.uploader = this.mockUploader('filename', 35)
    this.node = $('<div>').appendTo('#fixtures')[0]
    this.progressContainer = ReactDOM.render(
      React.createFactory(ProgressContainer)({uploader: this.uploader}),
      this.node
    )
    this.prog = this.progressContainer.refs.prog
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.progressContainer).parentNode)
    $('#fixtures').empty()
  },
  mockUploader(name, progress) {
    const uploader = new FileUploader({file: {}})
    sandbox.stub(uploader, 'getFileName').returns(name)
    sandbox.stub(uploader, 'roundProgress').returns(progress)
    return uploader
  }
})

test('getLabel displays file name', function() {
  equal(this.prog.refs.fileName.textContent, 'filename')
})

test('announces upload progress to screen reader when queue changes', function() {
  sandbox.stub($, 'screenReaderFlashMessage')
  equal(this.prog.props.uploader.roundProgress(), 35)

  // File upload 75% complete
  this.progressContainer.setState({uploader: this.mockUploader('filename', 75)})
  equal(this.prog.props.uploader.roundProgress(), 75)

  // File upload complete
  equal($.screenReaderFlashMessage.calledWith('filename - 75 percent uploaded'), true)
  this.progressContainer.setState({uploader: this.mockUploader('filename', 100)})
  equal(this.prog.props.uploader.roundProgress(), 100)
  equal($.screenReaderFlashMessage.calledWith('filename uploaded successfully!'), true)
})

test('does not announce upload progress to screen reader if progress has not changed', function() {
  sandbox.stub($, 'screenReaderFlashMessage')
  equal(this.prog.props.uploader.roundProgress(), 35)

  // Simulates a "componentWillReceiveProps"
  this.progressContainer.setState({uploader: this.mockUploader('filename', 35)})
  this.progressContainer.setState({uploader: this.mockUploader('filename', 35)})
  equal(this.prog.props.uploader.roundProgress(), 35)
  equal($.screenReaderFlashMessage.calledOnce, true)
})
