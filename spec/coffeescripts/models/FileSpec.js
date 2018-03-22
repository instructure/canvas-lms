/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import File from 'compiled/models/File'
import {Model} from 'Backbone'
import * as uploader from 'jsx/shared/upload_file'

let model = null

QUnit.module('File', {
  setup() {
    const $el = $('<input type="file">')
    model = new File(null, {preflightUrl: '/preflight'})
    model.set({file: $el[0]})
  }
})

test('uploads the file, and sets attributes from response', function(assert) {
  const done = assert.async()
  const data = {
    id: 123,
    filename: 'example'
  }
  const uploadStub = this.stub(uploader, 'uploadFile')
  uploadStub.returns(Promise.resolve(data))
  const setStub = this.stub(Model.prototype, 'set')
  const dfrd = model.save()
  ok(uploadStub.called, 'uploaded the file')
  dfrd.done(() => {
    ok(setStub.calledWith(data), 'set response data')
    done()
  })
})
