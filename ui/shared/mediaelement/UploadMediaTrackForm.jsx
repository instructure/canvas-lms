//
// Copyright (C) 2011 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import template from './jst/UploadMediaTrackForm.handlebars'
// eslint-disable-next-line import/no-cycle
import mejs from './index'
import $ from 'jquery'
import {map} from 'lodash'

import CopyToClipboard from '@canvas/copy-to-clipboard'
import React from 'react'
import ReactDOM from 'react-dom'

const I18n = useI18nScope('UploadMediaTrackForm')

export default class UploadMediaTrackForm {
  // video url needs to be the url to mp4 version of the video.
  constructor(mediaCommentId, video_url, attachmentId = null, lockedMediaAttachment = false) {
    this.mediaCommentId = mediaCommentId
    this.video_url = video_url
    this.attachmentId = attachmentId
    this.lockedMediaAttachment = lockedMediaAttachment
    const templateVars = {
      languages: map(mejs.language.codes, (name, code) => ({name, code})),
      video_url: this.video_url,
      is_amazon_url: this.video_url.search(/.mp4/) !== -1,
    }
    this.$dialog = $(template(templateVars))
      .appendTo('body')
      .dialog({
        close: () => this.$dialog.remove(),
        width: 650,
        resizable: false,
        buttons: [
          {
            'data-text-while-loading': I18n.t('cancel', 'Cancel'),
            text: I18n.t('cancel', 'Cancel'),
            click: () => this.$dialog.remove(),
          },
          {
            class: 'btn-primary',
            'data-text-while-loading': I18n.t('uploading', 'Uploading...'),
            text: I18n.t('upload', 'Upload'),
            click: this.onSubmit,
          },
        ],
        modal: true,
        zIndex: 1000,
      })

    ReactDOM.render(
      <CopyToClipboard interaction="readonly" name="video_url" value={video_url} />,
      document.getElementById('media-track-video-url-container')
    )
  }

  onSubmit = () => {
    const submitDfd = new $.Deferred()
    submitDfd.fail(() => this.$dialog.find('.invalidInputMsg').show())

    this.$dialog.disableWhileLoading(submitDfd)
    this.getFileContent()
      .fail(() => submitDfd.reject())
      .done(content => {
        const params = {
          content,
          locale: this.$dialog.find('[name="locale"]').val(),
        }

        if (!params.content || !params.locale) return submitDfd.reject()

        const url =
          ENV.FEATURES.media_links_use_attachment_id && this.attachmentId
            ? `/media_attachments/${this.attachmentId}/media_tracks`
            : `/media_objects/${this.mediaCommentId}/media_tracks`
        return $.ajaxJSON(
          url,
          'POST',
          params,
          () => {
            submitDfd.resolve()
            this.$dialog.dialog('close')
            $.flashMessage(
              I18n.t(
                'track_uploaded_successfully',
                'Track uploaded successfully; please refresh your browser.'
              )
            )
          },
          () => {
            submitDfd.reject()
          }
        )
      })
  }

  getFileContent() {
    const dfd = new $.Deferred()
    const file = this.$dialog.find('input[name="content"]')[0].files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = function (e) {
        const content = e.target.result
        return dfd.resolve(content)
      }
      reader.readAsText(file)
    } else {
      dfd.reject()
    }
    return dfd
  }
}
