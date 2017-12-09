#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'compiled/views/profiles/UploadFileView'
  'compiled/util/BlobFactory'
], (UploadFileView, BlobFactory) ->

  QUnit.module 'UploadFileView',
    setup: ->
      @resolveImageLoaded = null
      @imageLoaded = new Promise((resolve) => @resolveImageLoaded = resolve)
      @view  = new UploadFileView(avatarSize: { h: 128, w: 128 }, onImageLoaded: @resolveImageLoaded)
      @view.$el.appendTo('#fixtures')
      @file  = (->
        dfd    = $.Deferred()
        xhr  = new XMLHttpRequest()
        xhr.open('GET', '/base/spec/javascripts/fixtures/pug.jpg')
        xhr.responseType = 'blob'
        xhr.onload = (e) ->
          response = BlobFactory.fromXHR(@response, 'image/jpeg')
          dfd.resolve(response)
        xhr.send()
        dfd
      )()
      @view.render()

    teardown: ->
      delete @blob
      @view.remove()
      $(".ui-dialog").remove()

  asyncTest 'loads given file', 3, ->
    # initial state
    ok @view.$el.find('.avatar-preview').length == 0, 'picker begins without preview image'

    $.when(@file).pipe(@view.loadPreview)
    @imageLoaded.then(=>
      # loaded state
      $preview  = @view.$('.avatar-preview')
      $fullsize = @view.$('img.Cropper-image')

      ok $preview.length > 0,                     'preview image exists'
      ok $fullsize.attr('src') != '',             'image loader contains loaded image after load'

      start()
    )

  asyncTest 'getImage returns cropped image object', 1, ->
    $.when(@file).pipe(@view.loadPreview)
    @imageLoaded.then(=>
      @view.getImage().then((image) ->
        ok image instanceof Blob, 'image object is a blob'
        start()
      )
    )
