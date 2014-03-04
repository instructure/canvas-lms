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
  'jquery'
  'underscore'
  'compiled/views/profiles/AvatarUploadBaseView'
  'jst/profiles/takePictureView'
  'compiled/util/BlobFactory'
], ($, _, BaseView, template, BlobFactory) ->

  class TakePictureView extends BaseView

    @optionProperty 'avatarSize'

    template: template

    events:
      'click .take-snapshot-btn'  : 'onSnapshot'
      'click .retry-snapshot-btn' : 'onRetry'

    els:
      '.webcam-live-preview'         : '$video'
      '.webcam-clip'                 : '$clip'
      '.webcam-preview'              : '$preview'
      '.webcam-capture-wrapper'      : '$captureWrapper'
      '.webcam-preview-wrapper'      : '$previewWrapper'
      '.webcam-preview-staging-area' : '$canvas'

    getUserMedia: (navigator.getUserMedia or navigator.mozGetUserMedia or
      navigator.msGetUserMedia or navigator.webkitGetUserMedia or $.noop).bind(navigator)

    setup: ->
      @startMedia()

    teardown: ->
      delete @img
      delete @preview

    startMedia: ->
      @getUserMedia(video: true, @displayMedia, $.noop)

    displayMedia: (stream) =>
      @$video.removeClass('pending')
      @$video.attr('src', window.URL.createObjectURL(stream))
      @$video.on('onloadedmetadata loadedmetadata', _.once(@onMediaMetadata).bind(this))

    onMediaMetadata: (e) ->
      wait = window.setInterval(=>
        return unless @$video[0].videoHeight != 0
        window.clearInterval(wait)

        clipSize  = _.min([@$video.height(), @$video.width()])
        @$clip.height(clipSize).width(clipSize)

        if @$video.width() > clipSize
          adjustment = ((@$video.width() - clipSize) / 2) * -1
          @$video.css('left', adjustment)
      , 100)

    toggleView: ->
      @$captureWrapper.toggle()
      @$previewWrapper.toggle()
      @trigger('ready', !!@preview)

    getImage: ->
      dfd = $.Deferred()
      dfd.resolve(@img)

    onSnapshot: ->
      canvas  = @$canvas[0]
      video   = @$video[0]
      img     = new Image
      context = canvas.getContext('2d')

      canvas.height = video.clientHeight
      canvas.width = video.clientWidth
      context.drawImage(
        # source
        video,

        # x and y coordinates of the top-left corner of the source image to draw to destination
        0, 0,

        # width and height of the source image to draw to the destination
        canvas.width, canvas.height
      )
      url = canvas.toDataURL()

      img.onload = (e) =>
        sX = (video.clientWidth - @$clip.width())   / 2
        sY = (video.clientHeight - @$clip.height()) / 2

        canvas.height = @$clip.height()
        canvas.width  = @$clip.width()

        context.drawImage(
          # source
          img,

          # x and y coordinates of the top-left corner of the source image to draw to destination
          sX, sY,

          # width and height of the source image to draw to the destination
          @$clip.width(), @$clip.height(),

          # x and y coordinates to start drawing to in the destination
          0, 0,

          # width and height of the image in the destination
          @$clip.width(), @$clip.height()
        )

        @preview = canvas.toDataURL()
        @toggleView()
        @$preview.attr('src', @preview)
        @img = BlobFactory.fromCanvas(canvas)

      img.src = url

    onRetry: (e) ->
      @resetSnapshot()

    resetSnapshot: ->
      delete @preview
      delete @img
      @toggleView()

    previewSrc: ->
      return '' unless @preview
      @preview.split(',')[1]

    toJSON: ->
      { hasPreview: !!@preview, previewURL: @preview }
