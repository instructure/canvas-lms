/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useEffect, useState} from 'react'
import {useInterval} from 'react-use'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('convert_allocations')

export const CONVERSION_JOB_NOT_STARTED = 'not_started'
export const CONVERSION_JOB_QUEUED = 'queued'
export const CONVERSION_JOB_RUNNING = 'running'
export const CONVERSION_JOB_COMPLETE = 'complete'
export const CONVERSION_JOB_FAILED = 'failed'

export type ConversionJobState =
  | typeof CONVERSION_JOB_NOT_STARTED
  | typeof CONVERSION_JOB_QUEUED
  | typeof CONVERSION_JOB_RUNNING
  | typeof CONVERSION_JOB_COMPLETE
  | typeof CONVERSION_JOB_FAILED

export type ConversionAction = 'convert' | 'delete'

interface ConversionStatusResponse {
  workflow_state: string
  progress?: number
}

export function useConvertAllocations(courseId: string, assignmentId: string) {
  const [conversionJobState, setConversionJobState] = useState<ConversionJobState>(
    CONVERSION_JOB_NOT_STARTED,
  )
  const [conversionJobProgress, setConversionJobProgress] = useState(0)
  const [conversionJobError, setConversionJobError] = useState<string | null>(null)
  const [conversionAction, setConversionAction] = useState<ConversionAction>('convert')
  const [pollJobProgress, setPollJobProgress] = useState(false)

  useInterval(
    () => {
      getJobProgress()
    },
    pollJobProgress ? 1000 : null,
  )

  const getJobProgress = async () => {
    const path = `/api/v1/courses/${courseId}/assignments/${assignmentId}/convert_peer_review_allocations/status`

    try {
      const {json, response} = await doFetchApi<ConversionStatusResponse>({path})

      if (response.ok && json) {
        setConversionJobProgress(json.progress ?? conversionJobProgress)
        if (json.workflow_state === 'queued') {
          setConversionJobState(CONVERSION_JOB_QUEUED)
        } else if (json.workflow_state === 'running') {
          setConversionJobState(CONVERSION_JOB_RUNNING)
        } else if (json.workflow_state === 'completed') {
          setConversionJobState(CONVERSION_JOB_COMPLETE)
          setPollJobProgress(false)
        } else if (json.workflow_state === 'failed') {
          setConversionJobState(CONVERSION_JOB_FAILED)
          setPollJobProgress(false)
          setConversionJobError(I18n.t('The conversion job failed.'))
        }
      }
    } catch (_error) {
      setConversionJobState(CONVERSION_JOB_FAILED)
      setPollJobProgress(false)
      setConversionJobError(I18n.t('An error occurred while fetching job progress.'))
    }
  }

  const launch = async (shouldDelete: boolean) => {
    const path = `/api/v1/courses/${courseId}/assignments/${assignmentId}/convert_peer_review_allocations`
    const action: ConversionAction = shouldDelete ? 'delete' : 'convert'
    setConversionAction(action)

    try {
      const {response} = await doFetchApi({
        path,
        method: 'PUT',
        body: {type: 'AssessmentRequest', should_delete: shouldDelete},
      })

      if (response.status === 204) {
        setConversionJobState(CONVERSION_JOB_QUEUED)
        setConversionJobError(null)
        setPollJobProgress(true)
      }
    } catch (_error) {
      setConversionJobState(CONVERSION_JOB_FAILED)
      setPollJobProgress(false)
      setConversionJobError(
        shouldDelete
          ? I18n.t('An error occurred while starting the deletion.')
          : I18n.t('An error occurred while starting the conversion.'),
      )
    }
  }

  const launchConversion = () => launch(false)
  const launchDeletion = () => launch(true)

  useEffect(() => {
    return () => {
      setPollJobProgress(false)
    }
  }, [])

  return {
    launchConversion,
    launchDeletion,
    conversionAction,
    conversionJobState,
    conversionJobProgress,
    conversionJobError,
  }
}
