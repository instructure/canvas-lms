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
  'underscore'
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/files/ZipFileOptionsForm'
  ], ($, _, React, ReactDOM, TestUtils, ZipFileOptionsForm ) ->

    QUnit.module "ZipFileOptionsForm"

    test "creates a display message based on fileOptions ", ->
      props = {
        fileOptions: {file: {name: 'neat_file'}}
        onZipOptionsResolved: () ->
      }

      zFOF = TestUtils.renderIntoDocument(React.createElement(ZipFileOptionsForm, props))
      equal $(".modalMessage").text(), "Would you like to expand the contents of \"neat_file\" into the current folder, or upload the zip file as is?", "message is displayed"
      ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)

    test "handleExpandClick expands zip", ->
      zipOptionsResolvedStub = @stub()

      props = {
        fileOptions: {file: 'the_file_obj' }
        onZipOptionsResolved: zipOptionsResolvedStub
      }

      zFOF = TestUtils.renderIntoDocument(React.createElement(ZipFileOptionsForm, props))
      TestUtils.Simulate.click($(".btn-primary")[0])

      ok zipOptionsResolvedStub.calledWithMatch({file: 'the_file_obj', expandZip: false}), "resolves with correct options"

      ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)

    # skip if webpack: CNVS-33471
    # note: does not fail when only this spec is run
    if window.hasOwnProperty("define")
      test "handleUploadClick uploads zip", ->
        zipOptionsResolvedStub = @stub()

        props = {
          fileOptions: {file: 'the_file_obj' }
          onZipOptionsResolved: (options)->
            zipOptionsResolvedStub(options)
        }

        zFOF = TestUtils.renderIntoDocument(React.createElement(ZipFileOptionsForm, props))
        TestUtils.Simulate.click($(".btn")[0])

        ok zipOptionsResolvedStub.calledWithMatch({file: 'the_file_obj', expandZip: true}), "resolves with correct options"

        ReactDOM.unmountComponentAtNode(zFOF.getDOMNode().parentNode)
    else
      QUnit.skip "handleUploadClick uploads zip"
