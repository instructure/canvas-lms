//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import {map} from 'lodash'

/*
xsslint xssable.receiver.whitelist builder
*/

export default {
  fromCanvas(canvas, type = 'image/jpeg') {
    const url = canvas.toDataURL(type)
    const binary = atob(url.split(',')[1])
    const codes = map(binary, char => char.charCodeAt(0))
    const data = new Uint8Array(codes)
    return this._newBlob(data, type)
  },

  fromXHR(response, type = 'image/jpeg') {
    return this._newBlob(response, type)
  },

  _newBlob(src, type) {
    const builder = this._blobBuilder()
    if (builder) {
      builder.append(src)
      return builder.getBlob(type)
    } else {
      return new Blob([src], {type})
    }
  },

  _blobBuilder() {
    if (typeof window.Blob === 'function') return null

    window.BlobBuilder =
      window.BlobBuilder ||
      window.WebKitBlobBuilder ||
      window.MozBlobBuilder ||
      window.MSBlobBuilder
    if (typeof window.BlobBuilder === 'undefined') return null
    return new window.BlobBuilder()
  },
}
