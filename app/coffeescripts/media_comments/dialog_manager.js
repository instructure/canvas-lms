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

import I18n from 'i18n!media_comments'
import $ from 'jquery'
import 'jqueryui/dialog'
import ReactDOM from 'react-dom'

/*
 * manages uploader modal dialog
 */

export default class DialogManager {
  constructor() {
    this.hide = this.hide.bind(this)
    this.setCloseOption = this.setCloseOption.bind(this)
  }

  initialize() {
    this.dialog = $('#media_comment_dialog')
    return this.createLoadingWindow()
  }

  hide() {
    $('#media_comment_dialog').dialog('close')
  }

  createLoadingWindow() {
    if (this.dialog.length === 0) {
      this.dialog = $('<div/>').attr('id', 'media_comment_dialog')
    }
    this.dialog.text(I18n.t('messages.loading', 'Loading...'))
    this.dialog.dialog({
      title: I18n.t('titles.record_upload_media_comment', 'Record/Upload Media Comment'),
      resizable: false,
      width: 470,
      height: 300,
      modal: true
    })
    return (this.dialog = $('#media_comment_dialog'))
  }

  displayContent(html) {
    return this.dialog.html(html)
  }

  mediaReady(mediaType, opts) {
    this.showUpdateDialog()
    this.setCloseOption(opts)
    this.resetRecordHolders()
    return this.setupTypes(mediaType)
  }

  showUpdateDialog() {
    return this.dialog.dialog({
      title: I18n.t('titles.record_upload_media_comment', 'Record/Upload Media Comment'),
      width: 650,
      height: 550,
      modal: true
    })
  }

  setCloseOption(opts) {
    return this.dialog.dialog('option', 'close', () => {
      ReactDOM.unmountComponentAtNode(document.getElementById('record_media_tab'))
      $('#audio_record')
        .before("<div id='audio_record'/>")
        .remove()
      $('#video_record')
        .before("<div id='video_record'/>")
        .remove()
      if (opts && opts.close && $.isFunction(opts.close)) {
        return opts.close.call(this.$dialog)
      }
    })
  }

  setupTypes(mediaType) {
    if (mediaType === 'video') {
      $('#video_record_option').click()
      $('#media_record_option_holder').hide()
      $('#audio_upload_holder').hide()
      $('#video_upload_holder').show()
    } else if (mediaType === 'audio') {
      $('#audio_record_option').click()
      $('#media_record_option_holder').hide()
      $('#audio_upload_holder').show()
      $('#video_upload_holder').hide()
    } else {
      $('#video_record_option').click()
      $('#audio_upload_holder').show()
      $('#video_upload_holder').show()
    }
  }

  resetRecordHolders() {
    $('#audio_record')
      .before("<div id='audio_record'/>")
      .remove()
    $('#video_record')
      .before("<div id='video_record'/>")
      .remove()
  }

  activateTabs() {
    return this.dialog.find('#media_record_tabs').tabs()
  }
}
