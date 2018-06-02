/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import ZipFileOptionsForm from 'jsx/files/ZipFileOptionsForm'

QUnit.module('ZipFileOptionsForm')

test('creates a display message based on fileOptions ', () => {
  const props = {
    fileOptions: {file: {name: 'neat_file'}},
    onZipOptionsResolved() {}
  }
  const zFOF = TestUtils.renderIntoDocument(<ZipFileOptionsForm {...props} />)
  equal(
    $('.modalMessage').text(),
    'Would you like to expand the contents of "neat_file" into the current folder, or upload the zip file as is?',
    'message is displayed'
  )
  ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)
})

test('handleExpandClick expands zip', function() {
  const zipOptionsResolvedStub = this.stub()
  const props = {
    fileOptions: {file: 'the_file_obj'},
    onZipOptionsResolved: zipOptionsResolvedStub
  }
  const zFOF = TestUtils.renderIntoDocument(<ZipFileOptionsForm {...props} />)
  TestUtils.Simulate.click($('.btn-primary:contains("Upload It")')[0])
  ok(
    zipOptionsResolvedStub.calledWithMatch({
      file: 'the_file_obj',
      expandZip: false
    }),
    'resolves with correct options'
  )
  ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)
})

// skip if webpack: CNVS-33471
// note: does not fail when only this spec is run
if (window.hasOwnProperty('define')) {
  test('handleUploadClick uploads zip', function() {
    const zipOptionsResolvedStub = this.stub()
    const props = {
      fileOptions: {file: 'the_file_obj'},
      onZipOptionsResolved(options) {
        return zipOptionsResolvedStub(options)
      }
    }
    const zFOF = TestUtils.renderIntoDocument(<ZipFileOptionsForm {...props} />)
    TestUtils.Simulate.click($('.btn')[0])
    ok(
      zipOptionsResolvedStub.calledWithMatch({
        file: 'the_file_obj',
        expandZip: true
      }),
      'resolves with correct options'
    )
    ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)
  })
} else {
  QUnit.skip('handleUploadClick uploads zip')
}
