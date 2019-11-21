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

import $ from 'jquery'
import postGradesFrameDialog from 'jst/PostGradesFrameDialog'
import iframeAllowances from 'jsx/external_apps/lib/iframeAllowances'
import 'jqueryui/dialog'

export default class PostGradesFrameDialog
    constructor: (options) ->
      # init vars
      if options.returnFocusTo
        @returnFocusTo = options.returnFocusTo
      if options.baseUrl
        @baseUrl = options.baseUrl

      # init dialog
      @$dialog = $(postGradesFrameDialog({allowances: iframeAllowances()}))
      @$iframe = @$dialog.find('.post-grades-frame')
      @$dialog.on('dialogopen', @onDialogOpen)
      @$dialog.on('dialogclose', @onDialogClose)
      @$dialog.dialog
        autoOpen: false
        resizable: false
        width: 800
        height: 600
        dialogClass: 'post-grades-frame-dialog'

      # list for focus/blur events
      $('.before_external_content_info_alert, .after_external_content_info_alert').on('focus', (e) =>
        iframeWidth = @$iframe.outerWidth(true)
        iframeHeight = @$iframe.outerHeight(true)
        @$iframe.addClass('info_alert_outline')
        @$iframe.data('height-with-alert', iframeHeight)
        $(e.target).children('div').first().removeClass('screenreader-only')
        alertHeight = $(e.target).outerHeight(true)
        @$iframe.css('height', (iframeHeight - alertHeight - 4) + 'px')
          .css('width', (iframeWidth - 4) + 'px')
        @$dialog.scrollLeft(0).scrollTop(0)
      ).on('blur', (e) =>
        iframeWidth = @$iframe.outerWidth(true)
        iframeHeight = @$iframe.data('height-with-alert')
        @$iframe.removeClass('info_alert_outline')
        $(e.target).children('div').first().addClass('screenreader-only')
        @$iframe.css('height', iframeHeight + 'px')
          .css('width', iframeWidth + 'px')
        @$dialog.scrollLeft(0).scrollTop(0)
      )

      # other init
      if @baseUrl
        @$dialog.find(".post-grades-frame").attr('src', @baseUrl)

    open: =>
      @$dialog.dialog('open')

    close: =>
      @$dialog.dialog('close')

    onDialogOpen: (event) =>

    onDialogClose: (event) =>
      @$dialog.dialog('destroy').remove()
      if @returnFocusTo
        @returnFocusTo.focus()
