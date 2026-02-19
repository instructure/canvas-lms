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

import {useState} from 'react'
import {useScope as i18nScope} from '@canvas/i18n'
import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'
const I18n = i18nScope('page_views')

const EXPORT_TTL = 24 * 60 * 60 * 1000 // 24 hours
const POLL_FRESHNESS = 5 * 1000 // 5 seconds

export enum AsyncPageViewJobStatus {
  Queued = 'queued',
  Running = 'running',
  Finished = 'finished',
  Failed = 'failed',
  Empty = 'empty',
}
export interface AsyncPageviewJob {
  query_id: string
  name: string
  status: AsyncPageViewJobStatus
  createdAt: Date
  updatedAt: Date
  error_code: string | null
}

export interface AsyncPageviewJobResult {
  poll_url: string
}

function getLocalJSONArray(key: string): AsyncPageviewJob[] {
  const item = window.localStorage.getItem(key)
  if (!item) return []
  try {
    const arr = JSON.parse(item)
    if (!Array.isArray(arr)) return []
    return arr
  } catch (_error) {
    return []
  }
}

export function useAsyncPageviewJobs(
  key: string,
  userid: string,
): [
  AsyncPageviewJob[],
  (value: AsyncPageviewJob[]) => void,
  () => Promise<boolean>,
  (user: string, jobName: string, startDate: string, endDate: string) => Promise<void>,
  (record: AsyncPageviewJob) => Promise<string>,
] {
  const arr = getLocalJSONArray(key)
  const [jobs, _setJobs] = useState(arr.filter(notExpired))
  const BASE_URL = `/api/v1/users/${userid}/page_views`
  //const BASE_URL = 'http://localhost:8082/api/v5/pageviews' // for local pv5 mock

  function setJobs(value: AsyncPageviewJob[]) {
    const filtered = value.filter(notExpired)
    _setJobs(filtered)
    window.localStorage.setItem(key, JSON.stringify(filtered))
  }

  /**
   * Poll the status of async jobs. Returns true if the state did not change
   * and jobs are still in progress. This allows the caller to decide whether to
   * continue polling or not.
   */
  async function pollJobs() {
    // cancel polling if no jobs are in progress
    const job = jobs.find(isInProgress)
    if (job === undefined) return false

    // postpone polling if a job was updated recently
    const recentUpdatedJob = jobs.find(j => {
      const updatedAt = new Date(j.updatedAt)
      const age = new Date().getTime() - updatedAt.getTime()
      return age < POLL_FRESHNESS
    })
    if (recentUpdatedJob) {
      return true
    }

    try {
      const {json} = await doFetchApi<AsyncPageviewJob>({
        path: `${BASE_URL}/query/${job.query_id}`,
        method: 'GET',
      })
      if (json?.status) {
        // Update the status and the timestamp of the record
        const updatedJobs = jobs.map(record =>
          record.query_id === job.query_id
            ? {...record, status: json.status, updatedAt: new Date(), error_code: json.error_code}
            : record,
        )
        setJobs(updatedJobs)
        // state will change, polling can stop in this lifecycle
        return false
      }
      return jobs.filter(isInProgress).length > 0
    } catch (error) {
      // remove the job if status is 410 or 404
      if (error instanceof FetchApiError) {
        if (error.response.status === 404 || error.response.status === 410) {
          const updatedJobs = jobs.filter(record => record.query_id !== job.query_id)
          setJobs(updatedJobs)
          return false
        }
      }
      // Other errors are considered intermittent, so we keep polling
      return true
    }
  }

  async function postJob(user: string, jobName: string, startDate: string, endDate: string) {
    const {json} = await doFetchApi<AsyncPageviewJobResult>({
      path: `${BASE_URL}/query`,
      method: 'POST',
      body: {
        user: user,
        start_date: startDate,
        end_date: endDate,
        results_format: 'csv',
      },
    })
    if (json?.poll_url) {
      const query_id = json.poll_url.split('/').pop()
      if (!query_id) return
      if (jobs.find(j => j.query_id === query_id)) {
        // Already exists
        return
      }
      const newRecord: AsyncPageviewJob = {
        query_id: query_id,
        name: jobName,
        status: AsyncPageViewJobStatus.Queued,
        createdAt: new Date(),
        updatedAt: new Date(),
        error_code: null,
      }
      setJobs([newRecord, ...jobs])
    }
  }

  async function getDownloadUrl(record: AsyncPageviewJob): Promise<string> {
    const path = `${BASE_URL}/query/${record.query_id}/results`

    try {
      const {response} = await doFetchApi({
        path,
        method: 'HEAD',
      })

      // Check for 204 No Content (doFetchApi won't throw for this since it's 2xx)
      if (response.status === 204) {
        // No content, mark as empty
        const updatedJobs = jobs.map(job =>
          job.query_id === record.query_id ? {...job, status: AsyncPageViewJobStatus.Empty} : job,
        )
        setJobs(updatedJobs)
        throw new FetchApiError('No content available for download', response)
      }

      // If we get here, it's a successful response (200), download is ready
      return path
    } catch (error) {
      if (error instanceof FetchApiError) {
        const status = error.response.status

        // Handle job state updates based on response status for non-2xx responses
        if (status === 404 || status === 410) {
          // File not found or gone, remove from jobs
          const updatedJobs = jobs.filter(job => job.query_id !== record.query_id)
          setJobs(updatedJobs)
        }

        // For any error status, throw the FetchApiError for caller to handle
        throw error
      }

      // For non-HTTP errors (network issues, etc.), wrap in a generic error
      throw new Error(`Failed to check download status: ${error}`)
    }
  }

  return [jobs, setJobs, pollJobs, postJob, getDownloadUrl]
}

export function notExpired(record: AsyncPageviewJob) {
  const now = new Date()
  const createdAt = new Date(record.createdAt)
  const age = now.getTime() - createdAt.getTime()
  return age < EXPORT_TTL
}

// Display hours or minutes (within the hour)
export function displayTTL(record: AsyncPageviewJob) {
  if (isInProgress(record)) return I18n.t('Not yet')
  if (record.status === 'failed') return '-'
  if (record.status === 'empty') return '-'

  const age = new Date().getTime() - new Date(record.createdAt).getTime()
  const timeLeft = EXPORT_TTL - age
  if (timeLeft <= 0) return I18n.t('Expired')
  const hours = Math.round(timeLeft / 1000 / 60 / 60)
  const minutes = Math.round(timeLeft / 1000 / 60)
  if (hours > 1) return I18n.t('%{hours} hours', {hours})
  return I18n.t('%{minutes} minutes', {minutes})
}

export function isInProgress(j: AsyncPageviewJob) {
  return j.status === AsyncPageViewJobStatus.Queued || j.status === AsyncPageViewJobStatus.Running
}

export function statusColor(j: AsyncPageviewJob) {
  if (j.status === AsyncPageViewJobStatus.Finished) return 'success'
  if (j.status === AsyncPageViewJobStatus.Failed) return 'warning'
  if (j.status === AsyncPageViewJobStatus.Empty) return 'success'
  return 'info'
}

export function statusDisplayName(j: AsyncPageviewJob) {
  if (j.status === AsyncPageViewJobStatus.Queued) return I18n.t('In progress')
  if (j.status === AsyncPageViewJobStatus.Running) return I18n.t('In progress')
  if (j.status === AsyncPageViewJobStatus.Finished) return I18n.t('Completed')
  if (j.status === AsyncPageViewJobStatus.Failed) return I18n.t('Failed')
  if (j.status === AsyncPageViewJobStatus.Empty) return I18n.t('Empty')
  return j.status
}

export function errorCodeDisplayName(j: AsyncPageviewJob) {
  if (!j.error_code) {
    return I18n.t('Query failed. Please try again later.')
  }

  const errorCodeMap: {[key: string]: string} = {
    RESULT_SIZE_LIMIT_EXCEEDED: I18n.t(
      'The export result size limit was exceeded. Please narrow your date range and try again.',
    ),
    USER_FILTERED: I18n.t("This user's page view data is not available for export."),
  }
  return errorCodeMap[j.error_code] || I18n.t('Query failed. Please try again later.')
}
