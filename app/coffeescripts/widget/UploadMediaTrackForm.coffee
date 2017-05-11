#
# Copyright (C) 2011 - present Instructure, Inc.
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
  'i18n!media_comments'
  'underscore'
  'jst/widget/UploadMediaTrackForm'
  'vendor/mediaelement-and-player'
  'jquery'
], (I18n, _, template, mejs, $) ->

  class UploadMediaTrackForm

    # video url needs to be the url to mp4 version of the video.
    # it will be passed along to amara.org
    constructor: (@mediaCommentId, @video_url) ->
      templateVars =
        languages: _.map(mejs.language.codes, (name, code) -> {name, code})
        video_url: @video_url
        is_amazon_url: @video_url.search(/.mp4/) != -1
      @$dialog = $(template(templateVars))
        .appendTo('body')
        .dialog
          width: 650
          resizable: false
          buttons: [
            'data-text-while-loading' : I18n.t 'cancel', 'Cancel'
            text                      : I18n.t 'cancel', 'Cancel'
            click: => @$dialog.remove()
          ,
            class : 'btn-primary'
            'data-text-while-loading' :  I18n.t 'uploading', 'Uploading...'
            text: I18n.t 'upload', 'Upload'
            click: @onSubmit
          ]

    onSubmit: =>
      submitDfd = new $.Deferred()
      submitDfd.fail =>
        @$dialog.find('.invalidInputMsg').show()

      @$dialog.disableWhileLoading submitDfd
      @getFileContent().fail(-> submitDfd.reject()).done (content) =>

        params =
          content: content
          locale: @$dialog.find('[name="locale"]').val()

        return submitDfd.reject() unless params.content && params.locale


        $.ajaxJSON "/media_objects/#{@mediaCommentId}/media_tracks", 'POST', params, =>
          submitDfd.resolve()
          @$dialog.dialog('close')
          $.flashMessage I18n.t 'track_uploaded_successfully', "Track uploaded successfully; please refresh your browser."

    getFileContent: ->
      dfd = new $.Deferred
      file = @$dialog.find('input[name="content"]')[0].files[0]
      if file
        reader = new FileReader()
        reader.onload = (e) ->
          content = e.target.result
          dfd.resolve content
        reader.readAsText file
      else
        dfd.reject()
      dfd
