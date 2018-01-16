#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'compiled/models/File'
  'Backbone'
  'jsx/shared/upload_file'
], ($, File, {Model}, uploader) ->

  model = null

  QUnit.module 'File',
    setup: ->
      $el = $('<input type="file">')
      model = new File(null, preflightUrl: '/preflight')
      model.set file: $el[0]

  test 'uploads the file, and sets attributes from response', (assert) ->
    done = assert.async()
    data =
      id: 123
      filename: "example"
    uploadStub = @stub uploader, 'uploadFile'
    uploadStub.returns Promise.resolve(data)
    setStub = @stub Model.prototype, 'set'
    dfrd = model.save()
    ok uploadStub.called, "uploaded the file"
    dfrd.done =>
      ok setStub.calledWith(data), "set response data"
      done()
