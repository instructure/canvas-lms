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
import BaseView from './AvatarUploadBaseView'
import template from '../../jst/uploadFileView.handlebars'
import CropperMaker from '../../react/cropperMaker'

export default class UploadFileView extends BaseView {
  static initClass() {
    this.optionProperty('avatarSize')

    this.prototype.template = template

    this.prototype.events = {
      'click .select-photo-link': 'onChooseAvatar',
      'change #selected-photo': 'onSelectAvatar',
      'dragover .select-photo-link': 'onDragOver',
      'dragleave .select-photo-link': 'onDragLeave',
      'drop .select-photo-link': 'onFileDrop',
    }
  }

  onChooseAvatar(e) {
    e.preventDefault()
    return this.openFileDialog()
  }

  onSelectAvatar(e) {
    e.preventDefault()
    return this.loadPreview(e.target.files[0])
  }

  onDragLeave(_e) {
    return this.toggleOverStyle(false)
  }

  onDragOver(e) {
    e.stopPropagation()
    e.preventDefault()
    e.originalEvent.dataTransfer.dropEffect = 'copy'
    return this.toggleOverStyle(true)
  }

  onFileDrop(e) {
    e.stopPropagation()
    e.preventDefault()
    return this.loadPreview(e.originalEvent.dataTransfer.files[0])
  }

  openFileDialog() {
    return this.$('#selected-photo').click()
  }

  toggleOverStyle(force) {
    return this.$('.select-photo-link').toggleClass('over', force)
  }

  loadPreview = file => {
    if (!file.type.match(/^image/)) {
      alert('Invalid file type.')
      return false
    }
    return this.showPreview(file)
  }

  showPreview(file) {
    this.file = file
    this.render()
    return this.initCropping()
  }

  hidePreview() {
    delete this.file
    if (this.cropper) {
      this.cropper.unmount()
      delete this.cropper
    }
    return this.render()
  }

  render() {
    this.revokeURLObjects()
    return super.render(...arguments)
  }

  teardown() {
    this.hidePreview()
    return this.revokeURLObjects()
  }

  revokeURLObjects() {
    return this.$('img').each(function () {
      const src = $(this).attr('src')
      if (src.match(/^data/)) {
        return typeof window.URL.revokeObjectURL === 'function'
          ? window.URL.revokeObjectURL(src)
          : undefined
      }
    })
  }

  imageDimensions($preview, $fullSize) {
    const heightRatio = $fullSize.height() / $preview.height()
    const widthRatio = $fullSize.width() / $preview.width()

    return {
      heightRatio,
      widthRatio,
      x: Math.floor(this.currentCoords.x * widthRatio),
      y: Math.floor(this.currentCoords.y * heightRatio),
      w: Math.floor(this.currentCoords.w * widthRatio),
      h: Math.floor(this.currentCoords.h * heightRatio),
    }
  }

  getImage() {
    // crop returns a Promise, but we exepct getImage to return a Deferred
    const dfd = $.Deferred()
    this.cropper.crop().then(imageBlob => dfd.resolve(imageBlob))
    return dfd
  }

  initCropping() {
    if (!this.cropper) {
      this.cropper = new CropperMaker(this.$('.avatar-preview')[0], {
        imgFile: this.file,
        onImageLoaded: this.options.onImageLoaded,
        width: this.avatarSize.w,
        height: this.avatarSize.h,
      })
    }
    this.cropper.render()
    return this.trigger('ready')
  }

  toJSON() {
    return {hasPreview: !!this.file}
  }
}
UploadFileView.initClass()
