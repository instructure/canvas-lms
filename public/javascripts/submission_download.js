/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import INST from './INST'
import I18n from 'i18n!submissions'
import $ from 'jquery'
import htmlEscape from './str/htmlEscape'
import './jquery.ajaxJSON'
import 'jqueryui/dialog'
import 'jqueryui/progressbar'

INST.downloadSubmissions = function(url, onClose) {
  let cancelled = false
  const title = ENV.SUBMISSION_DOWNLOAD_DIALOG_TITLE || I18n.t('Download Assignment Submissions')

  $('#download_submissions_dialog')
    .dialog({
      title,
      close() {
        cancelled = true
      }
    })
    .on('dialogclose', onClose)
  $('#download_submissions_dialog .progress').progressbar({value: 0})
  const checkForChange = function() {
    if (cancelled || $('#download_submissions_dialog:visible').length === 0) {
      return
    }
    $('#download_submissions_dialog .status_loader').css('visibility', 'visible')
    let lastProgress = null
    $.ajaxJSON(
      url,
      'GET',
      {},
      data => {
        if (data && data.attachment) {
          const attachment = data.attachment
          if (attachment.workflow_state === 'zipped') {
            $('#download_submissions_dialog .progress').progressbar('value', 100)
            const message = I18n.t(
              '#submissions.finished_redirecting',
              'Finished!  Redirecting to File...'
            )
            const linkText = I18n.t('Click here to download %{size_of_file}', {
              size_of_file: attachment.readable_size
            })
            const link = `<a href="${htmlEscape(url)}"><b>${htmlEscape(linkText)}</b></a>`

            $('#download_submissions_dialog .status').html(
              `${htmlEscape(message)}<br>${$.raw(link)}`
            )
            $('#download_submissions_dialog .status_loader').css('visibility', 'hidden')

            location.href = url
            return
          } else {
            let progress = parseInt(attachment.file_state, 10)
            if (isNaN(progress)) {
              progress = 0
            }
            progress += 5
            $('#download_submissions_dialog .progress').progressbar('value', progress)
            let message = null
            if (progress >= 95) {
              message = I18n.t('#submissions.creating_zip', 'Creating zip file...')
            } else {
              message = I18n.t(
                '#submissions.gathering_files_progress',
                'Gathering Files (%{progress})...',
                {progress: I18n.toPercentage(progress)}
              )
            }
            $('#download_submissions_dialog .status').text(message)
            if (progress <= 5 || progress === lastProgress) {
              $.ajaxJSON(`${url}&compile=1`, 'GET', {}, () => {}, () => {})
            }
            lastProgress = progress
          }
        }
        $('#download_submissions_dialog .status_loader').css('visibility', 'hidden')
        setTimeout(checkForChange, 3000)
      },
      () => {
        $('#download_submissions_dialog .status_loader').css('visibility', 'hidden')
        setTimeout(checkForChange, 1000)
      }
    )
  }
  checkForChange()
}
