#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'jquery'
  'jst/PostGradesFrameDialog'
  'jqueryui/dialog'
], ($, postGradesFrameDialog) ->

  class PostGradesFrameDialog
    constructor: (options) ->
      # init vars
      if options.returnFocusTo
        @returnFocusTo = options.returnFocusTo
      if options.baseUrl
        @baseUrl = options.baseUrl

      # init dialog
      @$dialog = $(postGradesFrameDialog())
      @$dialog.on('dialogopen', @onDialogOpen)
      @$dialog.on('dialogclose', @onDialogClose)
      @$dialog.dialog
        autoOpen: false
        resizable: false
        width: Number(options.launchWidth) || 800
        height: Number(options.launchHeight) || 600
        dialogClass: 'post-grades-frame-dialog'
        
      # listen for external tool events

      # other init
      if @baseUrl
        @$dialog.find(".post-grades-frame").attr('src', @baseUrl)

    open: =>
      @$dialog.dialog('open')

    close: =>
      @$dialog.dialog('close')

    onDialogOpen: (event) =>
      $(window).on('externalContentReady', @close)
      $(window).on('externalContentCancel', @close)

    onDialogClose: (event) =>
      $(window).off('externalContentReady', @close);
      $(window).off('externalContentCancel', @close);
      @$dialog.dialog('destroy').remove()
      if @returnFocusTo
        @returnFocusTo.focus()
