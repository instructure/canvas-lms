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
  'i18n!media_comments',
  'jquery',
  'jqueryui/dialog'
], (I18n, $) ->

  ###
  # manages uploader modal dialog
  ###
  class DialogManager

    initialize: ->
      @dialog = $("#media_comment_dialog")
      @createLoadingWindow()

    hide: =>
      $('#media_comment_dialog').dialog('close')

    createLoadingWindow: ->
      if @dialog.length == 0
        @dialog = $("<div/>").attr('id', 'media_comment_dialog')
      @dialog.text(I18n.t('messages.loading', "Loading..."))
      @dialog.dialog({
        title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
        resizable: false,
        width: 470,
        height: 300,
        modal: true
      })
      @dialog = $('#media_comment_dialog')

    displayContent: (html) ->
      @dialog.html(html)

    mediaReady: (mediaType, opts) ->
      @showUpdateDialog()
      @setCloseOption(opts)
      @resetRecordHolders()
      @setupTypes(mediaType)

    showUpdateDialog: ->
      @dialog.dialog({
        title: I18n.t('titles.record_upload_media_comment', "Record/Upload Media Comment"),
        width: 560,
        height: 475,
        modal: true
      })

    setCloseOption: (opts) =>
      @dialog.dialog 'option', 'close', =>
        $("#audio_record").before("<div id='audio_record'/>").remove()
        $("#video_record").before("<div id='video_record'/>").remove()
        if(opts && opts.close && $.isFunction(opts.close))
          opts.close.call(@$dialog)

    setupTypes: (mediaType) ->
      if(mediaType == "video")
        $("#video_record_option").click()
        $("#media_record_option_holder").hide()
        $("#audio_upload_holder").hide()
        $("#video_upload_holder").show()
      else if(mediaType == "audio")
        $("#audio_record_option").click()
        $("#media_record_option_holder").hide()
        $("#audio_upload_holder").show()
        $("#video_upload_holder").hide()
      else
        $("#video_record_option").click()
        $("#audio_upload_holder").show()
        $("#video_upload_holder").show()

    resetRecordHolders: ->
      $("#audio_record").before("<div id='audio_record'/>").remove()
      $("#video_record").before("<div id='video_record'/>").remove()

    activateTabs: ->
      @dialog.find('#media_record_tabs').tabs()
