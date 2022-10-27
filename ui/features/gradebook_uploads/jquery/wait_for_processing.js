/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.ajaxJSON'
import 'spin.js/jquery.spin'

const I18n = useI18nScope('gradebook_uploads')

async function sleep(milliseconds) {
  return new Promise(resolve => {
    setTimeout(resolve, milliseconds)
  })
}

/**
 * The sleep_time parameter is included here to speed up testing.
 * There is an issue with jest.useFakeTimers and native Promises
 * that prevents this from being tested efficiently otherwise.
 * https://github.com/facebook/jest/issues/7151
 */
export async function waitForProcessing(progress, sleep_time = 2000) {
  const spinner = $('#spinner').spin()
  while (!['completed', 'failed'].includes(progress.workflow_state)) {
    /* eslint-disable no-await-in-loop */
    await sleep(sleep_time)
    progress = await $.ajaxJSON(`/api/v1/progress/${progress.id}`, 'GET').promise()
    /* eslint-enable no-await-in-loop */
  }

  if (progress.workflow_state === 'completed') {
    const uploadedGradebook = await $.ajaxJSON(ENV.uploaded_gradebook_data_path, 'GET').promise()
    spinner.hide()
    return uploadedGradebook
  } else if (progress.message?.includes('Invalid header row')) {
    throw new Error(I18n.t('The CSV header row is invalid.'))
  } else {
    throw new Error(
      I18n.t('An unknown error has occurred. Verify the CSV file or try again later.')
    )
  }
}
