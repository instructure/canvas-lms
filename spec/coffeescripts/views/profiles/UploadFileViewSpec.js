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

import UploadFileView from '@canvas/avatar-dialog-view/backbone/views/UploadFileView'
import BlobFactory from '@canvas/avatar-dialog-view/BlobFactory'

QUnit.module('UploadFileView', {
  setup() {
    this.resolveImageLoaded = null
    this.imageLoaded = new Promise(resolve => (this.resolveImageLoaded = resolve))
    this.view = new UploadFileView({
      avatarSize: {
        h: 128,
        w: 128,
      },
      onImageLoaded: this.resolveImageLoaded,
    })
    this.view.$el.appendTo('#fixtures')

    // This spec currently depends on a real XHR request to the file system.
    // Restoring the network will allow this spec to function correctly.
    sandbox.server.restore()
    this.file = (function () {
      const dfd = $.Deferred()
      const xhr = new XMLHttpRequest()
      xhr.open('GET', '/base/spec/javascripts/fixtures/pug.jpg')
      xhr.responseType = 'blob'
      xhr.onload = function (e) {
        const response = BlobFactory.fromXHR(this.response, 'image/jpeg')
        return dfd.resolve(response)
      }
      xhr.send()
      return dfd
    })()
    return this.view.render()
  },
  teardown() {
    delete this.blob
    this.view.remove()
    $('.ui-dialog').remove()
  },
})

test('loads given file', function (assert) {
  assert.expect(3)
  const start = assert.async()
  ok(this.view.$el.find('.avatar-preview').length === 0, 'picker begins without preview image')
  $.when(this.file).pipe(this.view.loadPreview)
  return this.imageLoaded.then(() => {
    const $preview = this.view.$('.avatar-preview')
    const $fullsize = this.view.$('img.Cropper-image')
    ok($preview.length > 0, 'preview image exists')
    ok($fullsize.attr('src') !== '', 'image loader contains loaded image after load')
    start()
  })
})

test('getImage returns cropped image object', function (assert) {
  assert.expect(1)
  const start = assert.async()
  $.when(this.file).pipe(this.view.loadPreview)
  return this.imageLoaded.then(() =>
    this.view.getImage().then(image => {
      ok(image instanceof Blob, 'image object is a blob')
      start()
    })
  )
})
