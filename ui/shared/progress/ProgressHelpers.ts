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
import doFetchApi from '@canvas/do-fetch-api-effect'

const DEFAULT_POLLING_INTERVAL_MS = 1000

export interface CanvasProgress {
  id: string
  workflow_state: 'queued' | 'running' | 'failed' | 'completed'
  message: string | null
  completion: number | null
  results: any | undefined
}

function progressAtEndState(progress: CanvasProgress): boolean {
  return progress && ['completed', 'failed'].includes(progress.workflow_state)
}

export function monitorProgress(
  progressId: string,
  setCurrentProgress: (progress: CanvasProgress) => void,
  onFetchError: (error: Error) => void,
  pollingIntervalMs = DEFAULT_POLLING_INTERVAL_MS,
) {
  let progress: CanvasProgress

  const pollApiProgress = () => {
    if (!progressId) return
    if (progressAtEndState(progress)) return

    const pollingLoop = () => {
      doFetchApi<CanvasProgress>({
        path: `/api/v1/progress/${progressId}`,
      })
        .then(result => {
          progress = result.json!
          if (!progressAtEndState(progress)) {
            window.setTimeout(pollingLoop, pollingIntervalMs)
          }
          setCurrentProgress(progress)
        })
        .catch((error: Error) => {
          onFetchError(error)
        })
    }
    pollingLoop()
  }
  pollApiProgress()
}

export function cancelProgressAction(
  progress: CanvasProgress | undefined,
  onCancelComplete: (error?: Error) => void,
) {
  if (!progress) return
  if (progressAtEndState(progress)) return

  doFetchApi<CanvasProgress>({
    path: `/api/v1/progress/${progress.id}/cancel`,
    method: 'POST',
    body: {message: 'canceled'},
  })
    .then(_result => {
      onCancelComplete()
    })
    .catch(onCancelComplete)
}
