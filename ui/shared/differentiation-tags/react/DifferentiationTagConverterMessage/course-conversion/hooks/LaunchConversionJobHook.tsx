/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import axios from 'axios'
import {useEffect, useState} from 'react'
import {useInterval} from 'react-use'

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

export default function useLaunchConversionJobHook(courseId: string, activeConversionJob: boolean) {
  const [conversionJobState, setConversionJobState] = useState<ConversionJobState>(
    activeConversionJob ? CONVERSION_JOB_RUNNING : CONVERSION_JOB_NOT_STARTED,
  )
  const [conversionJobProgress, setConversionJobProgress] = useState(0)
  const [conversionJobError, setConversionJobError] = useState<string | null>(null)
  const [pollJobProgress, setPollJobProgress] = useState(false)

  // Set the interval for polling job progress
  useInterval(
    () => {
      getJobProgress()
    },
    pollJobProgress ? 1000 : null,
  )

  const stopJobProgressPolling = () => {
    setPollJobProgress(false)
  }

  const startJobProgressPolling = () => {
    setPollJobProgress(true)
  }

  const getJobProgress = async () => {
    const url = `/api/v1/courses/${courseId}/convert_tag_overrides/status`

    try {
      const response = await axios.get(url)

      if (response.status === 200) {
        setConversionJobProgress(response.data.progress || conversionJobProgress)
        if (response.data.workflow_state === 'queued') {
          setConversionJobState(CONVERSION_JOB_QUEUED)
        } else if (response.data.workflow_state === 'running') {
          setConversionJobState(CONVERSION_JOB_RUNNING)
        } else if (response.data.workflow_state === 'completed') {
          setConversionJobState(CONVERSION_JOB_COMPLETE)
          stopJobProgressPolling()
        } else if (response.data.workflow_state === 'failed') {
          setConversionJobState(CONVERSION_JOB_FAILED)
          stopJobProgressPolling()
        }
      }
    } catch (_error) {
      setConversionJobState(CONVERSION_JOB_FAILED)
      stopJobProgressPolling()
      setConversionJobError('An error occurred while fetching job progress.')
    }
  }

  const launchConversionJob = async () => {
    const url = `/api/v1/courses/${courseId}/convert_tag_overrides`

    try {
      const response = await axios.put(url)

      if (response.status === 204) {
        setConversionJobState(CONVERSION_JOB_QUEUED)
        startJobProgressPolling()
      }
    } catch (_error) {
      setConversionJobState(CONVERSION_JOB_FAILED)
      stopJobProgressPolling()
    }
  }

  useEffect(() => {
    if (activeConversionJob) {
      startJobProgressPolling()
    }
    return () => {
      stopJobProgressPolling()
    }
  }, [activeConversionJob])

  return {
    launchConversionJob,
    conversionJobState,
    conversionJobProgress,
    conversionJobError,
  }
}
