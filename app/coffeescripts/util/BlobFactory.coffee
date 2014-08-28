#
# Copyright (C) 2013 Instructure, Inc.
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
#

define ['underscore'], (_) ->

  BlobFactory =
    fromCanvas: (canvas, type = 'image/jpeg') ->
      url    = canvas.toDataURL(type)
      binary = atob(url.split(',')[1])
      codes  = _.map(binary, (char) -> char.charCodeAt(0))
      data   = new Uint8Array(codes)
      @_newBlob(data, type)

    fromXHR: (response, type = 'image/jpeg') ->
      @_newBlob(response, type)

    _newBlob: (src, type) ->
      if builder = @_blobBuilder()
        builder.append(src)
        builder.getBlob(type)
      else
        new Blob([src], type: type)

    _blobBuilder: () ->
      return null if typeof window.Blob == 'function'

      window.BlobBuilder = window.BlobBuilder or window.WebKitBlobBuilder or window.MozBlobBuilder or window.MSBlobBuilder
      return null if typeof window.BlobBuilder == 'undefined'
      new BlobBuilder()
