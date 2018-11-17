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

import $ from 'jquery'
import _ from 'underscore'
import BaseView from './AvatarUploadBaseView'
import template from 'jst/profiles/takePictureView'
import BlobFactory from '../../util/BlobFactory'

export default class TakePictureView extends BaseView {
  static initClass() {
    this.optionProperty('avatarSize')

    this.prototype.template = template

    this.prototype.events = {
      'click .take-snapshot-btn': 'onSnapshot',
      'click .retry-snapshot-btn': 'onRetry'
    }

    this.prototype.els = {
      '.webcam-live-preview': '$video',
      '.webcam-clip': '$clip',
      '.webcam-preview': '$preview',
      '.webcam-capture-wrapper': '$captureWrapper',
      '.webcam-preview-wrapper': '$previewWrapper',
      '.webcam-preview-staging-area': '$canvas'
    }

    this.prototype.getUserMedia = (
      navigator.getUserMedia ||
      navigator.mozGetUserMedia ||
      navigator.msGetUserMedia ||
      navigator.webkitGetUserMedia ||
      $.noop
    ).bind(navigator)
  }

  setup() {
    return this.startMedia()
  }

  teardown() {
    delete this.img
    delete this.preview
    if (this.stream != null ? this.stream.stop : undefined) {
      return this.stream != null ? this.stream.stop() : undefined
    } else if (this.stream != null ? this.stream.getTracks : undefined) {
      // MediaStream.stop is deprecated in Chrome 45
      return this.stream != null
        ? this.stream.getTracks().forEach(track => track.stop())
        : undefined
    }
  }

  startMedia() {
    return this.getUserMedia({video: true}, this.displayMedia.bind(this), $.noop)
  }

  displayMedia(stream) {
    this.stream = stream
    this.$video.removeClass('pending')
    try {
      this.$video.get(0).srcObject = this.stream
    } catch (err) {
      this.$video.attr('src', window.URL.createObjectURL(this.stream))
    }
    return this.$video.on(
      'onloadedmetadata loadedmetadata',
      _.once(this.onMediaMetadata).bind(this)
    )
  }

  onMediaMetadata(e) {
    let wait
    return (wait = window.setInterval(() => {
      if (this.$video[0].videoHeight === 0) return
      window.clearInterval(wait)

      const clipSize = _.min([this.$video.height(), this.$video.width()])
      this.$clip.height(clipSize).width(clipSize)

      if (this.$video.width() > clipSize) {
        const adjustment = ((this.$video.width() - clipSize) / 2) * -1
        return this.$video.css('left', adjustment)
      }
    }, 100))
  }

  toggleView() {
    this.$captureWrapper.toggle()
    this.$previewWrapper.toggle()
    return this.trigger('ready', !!this.preview)
  }

  getImage() {
    const dfd = $.Deferred()
    return dfd.resolve(this.img)
  }

  onSnapshot() {
    const canvas = this.$canvas[0]
    const video = this.$video[0]
    const img = new Image()
    const context = canvas.getContext('2d')

    canvas.height = video.clientHeight
    canvas.width = video.clientWidth
    context.drawImage(
      // source
      video,

      // x and y coordinates of the top-left corner of the source image to draw to destination
      0,
      0,

      // width and height of the source image to draw to the destination
      canvas.width,
      canvas.height
    )
    const url = canvas.toDataURL()

    img.onload = e => {
      const sX = (video.clientWidth - this.$clip.width()) / 2
      const sY = (video.clientHeight - this.$clip.height()) / 2

      canvas.height = this.$clip.height()
      canvas.width = this.$clip.width()

      context.drawImage(
        // source
        img,

        // x and y coordinates of the top-left corner of the source image to draw to destination
        sX,
        sY,

        // width and height of the source image to draw to the destination
        this.$clip.width(),
        this.$clip.height(),

        // x and y coordinates to start drawing to in the destination
        0,
        0,

        // width and height of the image in the destination
        this.$clip.width(),
        this.$clip.height()
      )

      this.preview = canvas.toDataURL()
      this.toggleView()
      this.$preview.attr('src', this.preview)
      return (this.img = BlobFactory.fromCanvas(canvas))
    }

    return (img.src = url)
  }

  onRetry(e) {
    return this.resetSnapshot()
  }

  resetSnapshot() {
    delete this.preview
    delete this.img
    return this.toggleView()
  }

  previewSrc() {
    if (!this.preview) {
      return ''
    }
    return this.preview.split(',')[1]
  }

  toJSON() {
    return {hasPreview: !!this.preview, previewURL: this.preview}
  }
}
TakePictureView.initClass()
