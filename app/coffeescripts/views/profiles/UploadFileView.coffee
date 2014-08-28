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
  'vendor/jquery.jcrop'
], (_, BaseView, template, BlobFactory) ->

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
      dfd    = $.Deferred()
      reader = new FileReader()
      reader.onload = (e) =>
        @showPreview(e.target.result)
        dfd.resolve(e.target.result)
      reader.readAsDataURL(file)
      dfd

    showPreview: (dataURL) ->
      unless dataURL.match(/^data:image/)
        alert('Invalid file.')
        return false
      @preview = dataURL
      @render()
      @initCropping()

    hidePreview: ->
      delete @preview
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
      $preview  = @$('.avatar-preview')
      $fullSize = @$('#upload-fullsize-preview')
      canvas    = @$('#upload-canvas')[0]
      context   = canvas.getContext('2d')
      d         = @imageDimensions($preview, $fullSize)
      dfd       = $.Deferred()

      context.drawImage($fullSize[0], d.x, d.y, d.w, d.h, 0, 0, @avatarSize.w, @avatarSize.h)
      dfd.resolve(BlobFactory.fromCanvas(canvas, 'image/jpeg'))

    initCropping: ->
      # some browsers need some ticks to load the image
      wait = setInterval(=>
        $preview = @$('.avatar-preview')
        return unless $preview[0].complete
        clearInterval(wait)

        size     = _.min([$preview.height(), $preview.width()])
        $preview.Jcrop(
          aspectRatio : 1
          setSelect   : [0, 0, size, size]
          onSelect    : @saveCropPosition
          minSize     : [20, 20]
        )
        @trigger('ready')
      , 50) # some throttling

    saveCropPosition: (coords) =>
      @currentCoords = coords

    toJSON: ->
      { hasPreview: !!@preview, previewURL: @preview }
