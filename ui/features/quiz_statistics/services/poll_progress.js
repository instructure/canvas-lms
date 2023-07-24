/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import config from '../config'
import CoreAdapter from '@canvas/quiz-legacy-client-apps/adapter'
import K from '../constants'
import pickAndNormalize from '@canvas/quiz-legacy-client-apps/util/pick_and_normalize'

const Adapter = new CoreAdapter(config)

const fetchProgress = function (url) {
  return Adapter.request({
    type: 'GET',
    url,
  }).then(function (payload) {
    return pickAndNormalize(payload, K.PROGRESS_ATTRS)
  })
}

export default function pollProgress(url, options) {
  return new Promise((resolve, reject) => {
    let poller

    options = options || {}

    $(window).on('beforeunload.progress', function () {
      clearTimeout(poller)
    })

    const poll = function () {
      fetchProgress(url).then(function (data) {
        if (options.onTick) {
          options.onTick(data.completion, data)
        }

        if (data.workflowState === K.PROGRESS_FAILED) {
          reject()
        } else if (data.workflowState === K.PROGRESS_COMPLETE) {
          resolve()
        } else {
          poller = setTimeout(poll, options.interval || config.pollingFrequency)
        }
      }, reject)
    }

    poll()
  })
}
