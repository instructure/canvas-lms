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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import Ember from 'ember'
import register from '../helpers/register'
import '../../jst/components/ic-submission-download-dialog.hbs'
import 'jqueryui/progressbar'
import 'jqueryui/dialog'

const I18n = useI18nScope('submissions')

//  example usage:
//    {{
//      ic-submission-download-dialog
//      submissionsDownloadUrl=assignment_submissions_url
//    }}
export default register(
  'component',
  'ic-submission-download-dialog',
  Ember.Component.extend({
    isOpened: false,

    isChecking: true,

    attachment: {},

    percentComplete: 0,

    hideIndicator: Ember.computed.not('isChecking'),

    showFileLink: Ember.computed.equal('status', 'finished'),

    sizeOfFile: Ember.computed.alias('attachment.readable_size'),

    dialogTitle: I18n.t('download_submissions_title', 'Download Assignment Submissions'),

    bindFunctions: function () {
      this.reviewProgress = this.reviewProgress.bind(this)
      this.progressError = this.progressError.bind(this)
      return (this.checkForChange = this.checkForChange.bind(this))
    }.on('init'),

    status: function () {
      if (this.fileReady()) {
        return 'finished'
      } else if (this.get('percentComplete') >= 95) {
        return 'zipping'
      } else {
        return 'starting'
      }
    }.property('attachment', 'percentComplete', 'isOpened'),

    progress: function () {
      const attachment = this.get('attachment')
      let new_val = 0
      if (attachment && this.fileReady()) {
        new_val = 100
      } else if (attachment) {
        new_val = this.get('percentComplete')
        if (this.get('percentComplete') < 95) {
          new_val += 5
        }
        const state = parseInt(this.get('attachment.file_state'), 10)
        if (Number.isNaN(Number(state))) {
          new_val = 0
        }
      }

      return this.set('percentComplete', new_val)
    }.observes('attachment'),

    keepChecking: function () {
      if (this.get('percentComplete') !== 100 && !!this.get('isOpened')) {
        return true
      }
    }.property('percentComplete', 'isOpened'),

    url: function () {
      return `${this.get('submissionsDownloadUrl')}`
    }.property('submissionsDownloadUrl'),

    statusText: function () {
      switch (this.get('status')) {
        case 'starting':
          return I18n.t('gathering_files', 'Gathering Files (%{progress})...', {
            progress: I18n.toPercentage(this.get('percentComplete'), {precision: 0}),
          })
        case 'zipping':
          return I18n.t('creating_zip', 'Creating zip file...')
        case 'finished':
          return I18n.t('finished_redirecting', 'Finished!  Redirecting to File...')
      }
    }.property('status', 'percentComplete'),

    updateProgressBar: function () {
      return $('#progressbar').progressbar({value: this.get('percentComplete')})
    }.observes('percentComplete'),

    downloadCompletedFile: function () {
      if (this.get('percentComplete') === 100) {
        return (window.location.href = this.get('url'))
      }
    }.observes('percentComplete'),

    resetAttachment: function () {
      return this.set('attachment', null)
    }.observes('isOpened'),

    closeOnEsc: function (event) {
      if (event.keyCode === 27) {
        // esc
        return this.close()
      }
    }.on('keyDown'),

    actions: {
      openDialog() {
        this.set('isOpened', true)
        if (this.dialogOptions == null) {
          this.dialogOptions = {
            title: 'Download Assignment Submissions',
            resizable: false,
            modal: true,
            zIndex: 1000,
          }
        }
        if (this.$dialog == null) {
          this.$dialog = $('#submissions_download_dialog form').dialog(this.dialogOptions)
        }
        this.$dialog.dialog({
          modal: true,
          zIndex: 1000,
        })
        return this.checkForChange()
      },

      closeDialog() {
        return this.close()
      },
    },

    close() {
      this.$dialog.dialog('close')
      return this.set('isOpened', false)
    },

    fileReady() {
      const state = this.get('attachment.workflow_state')
      return state === 'zipped' || state === 'available'
    },

    checkForChange() {
      this.set('isChecking', true)
      return $.ajaxJSON(this.get('url'), 'GET', {}, this.reviewProgress, this.progressError)
    },

    reviewProgress(data) {
      this.set('isChecking', false)
      this.set('attachment', data.attachment)
      return this.setCheckTimeOut(3000)
    },

    progressError() {
      this.set('isChecking', false)
      return this.setCheckTimeOut(1000)
    },

    setCheckTimeOut(time) {
      if (this.get('keepChecking')) {
        return setTimeout(this.checkForChange, time)
      }
    },
  })
)
