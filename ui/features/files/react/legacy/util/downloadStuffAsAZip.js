/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {throttle} from 'lodash'
import Progress from '@canvas/progress/backbone/models/Progress'
import Folder from '@canvas/files/backbone/models/Folder'

const I18n = useI18nScope('react_files')

export default function downloadStuffAsAZip(filesAndFolders, {contextType, contextId}) {
  let promptBeforeLeaving
  const files = []
  const folders = []
  filesAndFolders.forEach(item => {
    if (item instanceof Folder) {
      folders.push(item.id)
    } else {
      files.push(item.id)
    }
  })

  const url = `/api/v1/${contextType}/${contextId}/content_exports`

  // This gives at least 2.5 seconds between updates of the status for screenreaders,
  // this should allow them to get the full message before it triggers another
  // reading of the message.  Technically, if the screenreader read speed is set
  // such that this is slower it won't work as intended.  But, most experienced
  // SR users set it much higher speed (300 wpm according to http://webaim.org/techniques/screenreader/)
  // This works well for the default read speed which is around 180 wpm.
  const screenreaderMessageWaitTimeMS = 2500
  const throttledSRMessage = throttle(
    $.screenReaderFlashMessageExclusive,
    screenreaderMessageWaitTimeMS,
    {leading: false}
  )

  // TODO: handle progress events with nicer UI
  const $progressIndicator = $(
    '<div style="position: fixed; top: 4px; left: 50%; margin-left: -120px; width: 240px; z-index: 11; text-align: center; box-sizing: border-box; padding: 8px;" class="alert alert-info">'
  )

  function onProgress(progessAPIResponse) {
    const message = I18n.t('progress_message', 'Preparing download: %{percent}% complete', {
      percent: progessAPIResponse.completion,
    })
    $progressIndicator.appendTo('body').text(message)
    return throttledSRMessage(message)
  }

  const data = {
    export_type: 'zip',
    select: {
      files,
      folders,
    },
  }

  $(window).on(
    'beforeunload',
    (promptBeforeLeaving = () =>
      I18n.t('If you leave, the zip file download currently being prepared will be canceled.'))
  )

  return $.post(url, data)
    .pipe(progressObject =>
      new Progress({url: progressObject.progress_url}).poll().progress(onProgress)
    )
    .pipe(progressObject => {
      const contentExportId = progressObject.context_id
      return $.getJSON(`${url}/${contentExportId}`)
    })
    .pipe(response => {
      $(window).off('beforeunload', promptBeforeLeaving)
      if (response.workflow_state === 'exported') {
        window.location = response.attachment.url
      } else {
        $.flashError(I18n.t('An error occurred trying to prepare download, please try again.'))
      }
    })
    .fail(() =>
      $.flashError(I18n.t('An error occurred trying to prepare download, please try again.'))
    )
    .always(() => {
      $(window).off('beforeunload', promptBeforeLeaving)
      $progressIndicator.remove()
    })
}
