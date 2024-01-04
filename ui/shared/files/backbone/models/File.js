/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import _, {clone, keys} from 'lodash'
import $ from 'jquery'
import FilesystemObject from './FilesystemObject'
import {uploadFile} from '@canvas/upload-file'
import '@canvas/jquery/jquery.ajaxJSON'

const slice = [].slice

extend(File, FilesystemObject)

// Simple model for creating an attachment in canvas
//
// Required stuff (or uploads won't work):
//
// 1. you need to pass a preflightUrl in the options
// 2. at some point, you need to do: `model.set('file', <input>)`
//    where <input> is the DOM node (not $-wrapped) of the file input
function File() {
  this.externalToolEnabled = this.externalToolEnabled.bind(this)
  return File.__super__.constructor.apply(this, arguments)
}

File.prototype.url = function () {
  if (this.isNew()) {
    // if it is new, fall back to Backbone's default behavior of using
    // the url of the collection this model belongs to.
    // aka: POST /api/v1/folders/:folder_id/files (to create)
    return File.__super__.url.apply(this, arguments)
  } else {
    // for GET, PUT, and DELETE, our API expects "/api/v1/files/:file_id"
    // not "/api/v1/folders/:folder_id/files/:file_id" which is what
    // backbone would do by default.
    return '/api/v1/files/' + this.id
  }
}

File.prototype.initialize = function (attributes, options) {
  if (options == null) {
    options = {}
  }
  this.preflightUrl = options.preflightUrl
  return File.__super__.initialize.apply(this, arguments)
}

File.prototype.save = function (attrs, options) {
  let file
  if (attrs == null) {
    attrs = {}
  }
  if (options == null) {
    options = {}
  }
  if (!this.get('file')) {
    return File.__super__.save.apply(this, arguments)
  }
  this.set(attrs)
  const dfrd = $.Deferred()
  const onUpload = (function (_this) {
    return function (data) {
      _this.set(data)
      dfrd.resolve(data)
      return typeof options.success === 'function' ? options.success(data) : void 0
    }
  })(this)
  const onError = (function (_this) {
    return function (error) {
      dfrd.reject(error)
      return typeof options.error === 'function' ? options.error(error) : void 0
    }
  })(this)
  file = this.get('file')
  const filename = (file.value || file.name).split(/[\/\\]/).pop()
  file = file.files[0]
  const preflightData = {
    name: filename,
    on_duplicate: 'rename',
  }
  uploadFile(this.preflightUrl, preflightData, file).then(onUpload).catch(onError)
  return dfrd
}

File.prototype.isFile = true

File.prototype.toJSON = function () {
  let ref
  if (!this.get('file')) {
    return File.__super__.toJSON.apply(this, arguments)
  }
  // eslint-disable-next-line prefer-spread
  return _.pick.apply(
    _,
    [this.attributes, 'file'].concat(slice.call(keys((ref = this.uploadParams) != null ? ref : {})))
  )
}

File.prototype.present = function () {
  return clone(this.attributes)
}

File.prototype.externalToolEnabled = function (tool) {
  if (tool.accept_media_types && tool.accept_media_types.length > 0) {
    const content_type = this.get('content-type')
    return _.find(tool.accept_media_types.split(','), function (t) {
      const regex = new RegExp('^' + t.replace('*', '.*') + '$')
      return content_type.match(regex)
    })
  } else {
    return true
  }
}

export default File
