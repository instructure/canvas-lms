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

import {useScope as useI18nScope} from '@canvas/i18n'
import {useEffect, useRef, useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {extractFetchErrorMessage} from '../utils'

const I18n = useI18nScope('assignments_bulk_edit_use_save_assignment')

export default function useMonitorJobCompletion({progressUrl, pollingInterval = 2000}) {
  const [jobCompletion, setJobCompletion] = useState(0)
  const [jobRunning, setJobRunning] = useState(false)
  const [jobSuccess, setJobSuccess] = useState(false)
  const [jobErrors, setJobErrors] = useState(null)

  useEffect(() => {
    let timeoutId = null
    let ignoreFetchResults = false

    function scheduleNextCompletionPoll() {
      timeoutId = setTimeout(startCompletionPoll, pollingInterval)
    }

    function reportJobErrors(json) {
      setJobRunning(false)
      setJobErrors(json.results)
    }

    async function reportFetchError(err) {
      setJobRunning(false)
      // this is also the results format if the job fails due to an exception
      setJobErrors({
        message: await extractFetchErrorMessage(
          err,
          I18n.t('There was an error retrieving job progress')
        ),
      })
    }

    function interpretCompletionResponse({json}) {
      if (ignoreFetchResults) return
      setJobCompletion(Math.floor(json.completion))
      if (json.workflow_state === 'failed') {
        setJobRunning(false)
        reportJobErrors(json)
      } else if (['queued', 'running'].includes(json.workflow_state)) {
        scheduleNextCompletionPoll()
      } else {
        setJobSuccess(true)
        setJobRunning(false)
      }
    }

    function startCompletionPoll() {
      setJobRunning(true)
      setJobSuccess(false)
      setJobErrors(null)
      doFetchApi({path: progressUrl}).then(interpretCompletionResponse).catch(reportFetchError)
    }

    // We really only want to start a polling session if the progressUrl changes, and not if just
    // one of the other dependencies change.
    if (progressUrl && progressUrl !== previousProgressUrlRef.current) {
      setJobCompletion(0)
      startCompletionPoll()
      return () => {
        // Either we're waiting on a fetch or on a timeout, so clear them both.
        ignoreFetchResults = true
        if (timeoutId) clearTimeout(timeoutId)
        setJobRunning(false)
      }
    }
  }, [progressUrl, pollingInterval])

  // This effect has to be declared second, or the above effect can't detect changes
  const previousProgressUrlRef = useRef(null)
  useEffect(() => {
    previousProgressUrlRef.current = progressUrl
  })

  return {
    jobCompletion,
    setJobCompletion,
    jobRunning,
    setJobRunning,
    jobSuccess,
    setJobSuccess,
    jobErrors,
    setJobErrors,
  }
}
