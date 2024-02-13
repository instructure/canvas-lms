// @ts-nocheck
/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import $ from 'jquery'
import type JQuery from 'jquery'
// @ts-expect-error
import postGradesFrameDialog from '../jst/PostGradesFrameDialog.handlebars'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import 'jqueryui/dialog'

type PostGradesFrameDialogOptions = {
  returnFocusTo?: HTMLElement | null
  baseUrl?: string
}

export default class PostGradesFrameDialog {
  returnFocusTo?: HTMLElement

  baseUrl?: string

  $dialog: JQuery

  $iframe

  constructor(options: PostGradesFrameDialogOptions) {
    this.open = this.open.bind(this)
    this.close = this.close.bind(this)
    this.onDialogOpen = this.onDialogOpen.bind(this)
    this.onDialogClose = this.onDialogClose.bind(this)

    // init vars
    if (options.returnFocusTo) {
      this.returnFocusTo = options.returnFocusTo
    }
    if (options.baseUrl) {
      this.baseUrl = options.baseUrl
    }

    // init dialog
    this.$dialog = $(
      postGradesFrameDialog({
        allowances: iframeAllowances(),
      })
    )

    this.$iframe = this.$dialog.find('.post-grades-frame')
    this.$dialog.on('dialogopen', this.onDialogOpen)
    this.$dialog.on('dialogclose', this.onDialogClose)
    this.$dialog.dialog({
      autoOpen: false,
      resizable: false,
      width: 800,
      height: 600,
      dialogClass: 'post-grades-frame-dialog',
      open() {
        const titleClose = $(this).parent().find('.ui-dialog-titlebar-close')
        if (titleClose.length) {
          titleClose.trigger('focus')
        }
      },
      modal: true,
      zIndex: 1000,
    })

    // list for focus/blur events
    $('.before_external_content_info_alert, .after_external_content_info_alert')
      .on('focus', e => {
        const iframeWidth = this.$iframe.outerWidth(true)
        const iframeHeight = this.$iframe.outerHeight(true)
        this.$iframe.addClass('info_alert_outline')
        this.$iframe.data('height-with-alert', iframeHeight)
        $(e.target).children('div').first().removeClass('screenreader-only')
        const alertHeight = $(e.target).outerHeight(true) || 0
        this.$iframe
          .css('height', iframeHeight - alertHeight - 4 + 'px')
          .css('width', iframeWidth - 4 + 'px')
        return this.$dialog.scrollLeft(0).scrollTop(0)
      })
      .on('blur', e => {
        const iframeWidth = this.$iframe.outerWidth(true)
        const iframeHeight = this.$iframe.data('height-with-alert')
        this.$iframe.removeClass('info_alert_outline')
        $(e.target).children('div').first().addClass('screenreader-only')
        this.$iframe.css('height', iframeHeight + 'px').css('width', iframeWidth + 'px')
        return this.$dialog.scrollLeft(0).scrollTop(0)
      })

    // other init
    if (this.baseUrl) {
      this.$dialog.find('.post-grades-frame').attr('src', this.baseUrl)
    }
  }

  open() {
    this.$dialog.dialog('open')
  }

  close() {
    this.$dialog.dialog('close')
  }

  onDialogOpen(_event) {}

  onDialogClose(_event) {
    this.$dialog.dialog('destroy').remove()
    if (this.returnFocusTo) {
      this.returnFocusTo.focus()
    }
  }
}
