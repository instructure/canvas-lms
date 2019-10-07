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

import I18n from 'i18n!UploadMediaTrackForm'
import _ from 'underscore'
import template from 'jst/widget/UploadMediaTrackForm'
import mejs from 'vendor/mediaelement-and-player'
import $ from 'jquery'

export default class UploadMediaTrackForm {
  // video url needs to be the url to mp4 version of the video.
  // it will be passed along to amara.org
  constructor(mediaCommentId, video_url) {
    this.mediaCommentId = mediaCommentId
    this.video_url = video_url
    const templateVars = {
      languages: _.map(mejs.language.codes, (name, code) => ({name, code})),
      video_url: this.video_url,
      is_amazon_url: this.video_url.search(/.mp4/) !== -1
    }
    this.$dialog = $(template(templateVars))
      .appendTo('body')
      .dialog({
        width: 650,
        resizable: false,
        buttons: [
          {
            'data-text-while-loading': I18n.t('cancel', 'Cancel'),
            text: I18n.t('cancel', 'Cancel'),
            click: () => this.$dialog.remove()
          },
          {
            class: 'btn-primary',
            'data-text-while-loading': I18n.t('uploading', 'Uploading...'),
            text: I18n.t('upload', 'Upload'),
            click: this.onSubmit
          }
        ]
      })
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
          locale: this.$dialog.find('[name="locale"]').val()
        }

        if (!params.content || !params.locale) return submitDfd.reject()

        return $.ajaxJSON(
          `/media_objects/${this.mediaCommentId}/media_tracks`,
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
      reader.onload = function(e) {
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
