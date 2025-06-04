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

import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation} from '@canvas/util/globalUtils'
import {type File, type Folder} from '../interfaces/File'
import {getIdFromUniqueId} from './fileFolderUtils'
import {doFetchApiWithAuthCheck, UnauthorizedError} from './apiUtils'

const I18n = createI18nScope('files_v2')

type ContentExportResponse = {
  workflow_state: string
  progress_url?: string
  attachment?: {
    url: string
  }
}

type PoolProgressResponse = {
  workflow_state: string
  completion: number
  context_id: string
}

interface EventListenerFunction {
  (event: Event): void
}

interface performRequestProps {
  items: Set<string>
  rows: (File | Folder)[]
  contextType: string
  contextId: string
  onProgress: (progress: number) => void
  onComplete: () => void
}

const custom_event = 'download_utils_event'

export const addDownloadListener = (f: EventListenerFunction): void =>
  window.addEventListener(custom_event, f)
export const removeDownloadListener = (f: EventListenerFunction): void =>
  window.removeEventListener(custom_event, f)

export const downloadFile = (url: string) => {
  assignLocation(url)
}

export const downloadZip = (items: Set<string>) => {
  window.dispatchEvent(new CustomEvent(custom_event, {detail: {items}}))
}

export const performRequest = ({
  items,
  rows,
  contextType,
  contextId,
  onProgress,
  onComplete,
}: performRequestProps) => {
  const url = `/api/v1/${contextType}/${contextId}/content_exports`
  const selectedItems: {files: string[]; folders: string[]} = {
    files: [],
    folders: [],
  }

  items.forEach(item => {
    const id = getIdFromUniqueId(item)
    if (item.includes('folder-')) {
      selectedItems.folders.push(id)
    } else {
      selectedItems.files.push(id)
    }
  })

  if (selectedItems.files.length == 1 && selectedItems.folders.length == 0) {
    downloadFile(rows.find(row => row.id.toString() == selectedItems.files[0])?.url || '')
    return false
  }

  window.addEventListener('beforeunload', promptBeforeLeaving, true)

  doFetchApiWithAuthCheck<ContentExportResponse>({
    path: `${url}`,
    method: 'POST',
    body: bodyToQueryString(selectedItems),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    },
  })
    .then(response => {
      return poolProgress(response.json?.progress_url || '', onProgress)
    })
    .then(response => {
      const json = (response as DoFetchApiResults<PoolProgressResponse>).json
      return doFetchApi<ContentExportResponse>({
        path: `${url}/${json?.context_id}`,
      })
    })
    .then(response => {
      const json = response.json || {workflow_state: 'failed'}
      removeBeforeLeaving()

      if (json.workflow_state == 'exported' && json.attachment?.url) {
        assignLocation(json.attachment.url)
      } else {
        throw new Error('Invalid attachment url')
      }
    })
    .catch(error => {
      if (error instanceof UnauthorizedError) {
        window.location.href = '/login'
        return
      }
      showFlashError(I18n.t('An error occurred trying to prepare download, please try again.'))(
        error,
      )
    })
    .finally(() => {
      removeBeforeLeaving()
      onComplete()
    })

  return true
}

const poolProgress = (url: string, onProgress: (progress: number) => void) => {
  return new Promise((resolve, reject) => {
    const poolRequest = () => {
      doFetchApiWithAuthCheck<PoolProgressResponse>({path: url})
        .then(response => {
          onProgress(response.json?.completion || 0)
          switch (response.json?.workflow_state || 'failed') {
            case 'completed':
              resolve(response)
              break
            case 'queued':
            case 'running':
              setTimeout(poolRequest, 1000)
              break
            case 'failed':
              reject(new Error(I18n.t('Export failed')))
              break
          }
        })
        .catch(error => {
          if (error instanceof UnauthorizedError) {
            window.location.href = '/login'
            return
          }
          reject(error)
        })
    }
    poolRequest()
  })
}

const promptBeforeLeaving = (e: Event) => {
  e.preventDefault()
  return I18n.t('If you leave, the zip file download currently being prepared will be canceled.')
}

const removeBeforeLeaving = () => {
  window.removeEventListener('beforeunload', promptBeforeLeaving, true)
}

// content_exports API does not handle json body
// this workaround pass a query string payload
const bodyToQueryString = (json: Record<string, any>) => {
  const formData = new FormData()
  formData.append('export_type', 'zip')
  Object.keys(json).forEach(function (k) {
    ;(json[k] as [string]).forEach(v => {
      formData.append(`select[${k}][]`, v)
    })
  })
  const params = new URLSearchParams(formData as unknown as Record<string, string>)
  return params.toString()
}
