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

define [
  'underscore'
  'compiled/views/profiles/AvatarUploadBaseView'
  'jst/profiles/uploadFileView'
  'compiled/util/BlobFactory'
  'jsx/canvas_cropper/cropperMaker'
], (_, BaseView, template, BlobFactory, CropperMaker) ->

  class UploadFileView extends BaseView

    @optionProperty 'avatarSize'

    template: template

    events:
      'click .select-photo-link'     : 'onChooseAvatar'
      'change #selected-photo'       : 'onSelectAvatar'
      'dragover .select-photo-link'  : 'onDragOver'
      'dragleave .select-photo-link' : 'onDragLeave'
      'drop .select-photo-link'      : 'onFileDrop'

    onChooseAvatar: (e) ->
      e.preventDefault()
      @openFileDialog()

    onSelectAvatar: (e) ->
      e.preventDefault()
      @loadPreview(e.target.files[0])

    onDragLeave: (e) ->
      @toggleOverStyle(false)

    onDragOver: (e) ->
      e.stopPropagation()
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'
      @toggleOverStyle(true)

    onFileDrop: (e) ->
      e.stopPropagation()
      e.preventDefault()
      @loadPreview(e.originalEvent.dataTransfer.files[0])

    openFileDialog: ->
      @$('#selected-photo').click()

    toggleOverStyle: (force) ->
      @$('.select-photo-link').toggleClass('over', force)

    loadPreview: (file) =>
      unless file.type.match(/^image/)
        alert('Invalid file type.')
        return false
      @showPreview(file)

    showPreview: (file) ->
      @file = file
      @render()
      @initCropping()

    hidePreview: ->
      delete @file
      if(@cropper)
        @cropper.unmount()
        delete @cropper
      @render()

    render: ->
      @revokeURLObjects()
      super

    teardown: ->
      @hidePreview()
      @revokeURLObjects()

    revokeURLObjects: ->
      @$('img').each(() ->
        src = $(this).attr('src')
        window.URL.revokeObjectURL?(src) if src.match(/^data/)
      )

    imageDimensions: ($preview, $fullSize) ->
      heightRatio = $fullSize.height() / $preview.height()
      widthRatio  = $fullSize.width() /  $preview.width()

      dimensions =
        heightRatio : heightRatio
        widthRatio  : widthRatio
        x           : Math.floor(@currentCoords.x  * widthRatio)
        y           : Math.floor(@currentCoords.y  * heightRatio)
        w           : Math.floor(@currentCoords.w  * widthRatio)
        h           : Math.floor(@currentCoords.h  * heightRatio)

    getImage: ->
      # crop returns a Promise, but we exepct getImage to return a Deferred
      dfd = $.Deferred()
      @cropper.crop().then((imageBlob) -> dfd.resolve(imageBlob))
      dfd

    initCropping: () ->
      if(!@cropper)
        @cropper = new CropperMaker(@$('.avatar-preview')[0], {imgFile: @file, width: @avatarSize.w, height: @avatarSize.h})
      @cropper.render()
      @trigger('ready')

    toJSON: ->
      { hasPreview: !!@file }
