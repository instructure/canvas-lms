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
import React from 'react'
import ReactDOM from 'react-dom'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconRefreshLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n/i18nObj'
import {FetchError} from '@canvas/context-modules/utils/FetchError'

const DEFAULT_PAGE_SIZE = 10
const BATCH_SIZE = 6

type ModuleId = number | string
type ModuleItems = string
type ModuleItemsCallback = (
  moduleId: ModuleId
) => void

function renderResult(moduleItemContainer: Element, text: string) {
  moduleItemContainer.insertAdjacentHTML('afterbegin', text)
}

function renderError(
  moduleItemContainer: Element,
  courseId: string,
  moduleId: ModuleId,
  callback: ModuleItemsCallback,
  per_page: number
) {
  const rootNodeForError = document.createElement('div')
  rootNodeForError.className = 'module-items-error-container'

  ReactDOM.render(
    <FetchError
      retryCallback={() => fetchModuleItemsHtml(courseId, moduleId, callback, per_page)}
    />,
    rootNodeForError,
  )
  moduleItemContainer.prepend(rootNodeForError)
}

async function fetchModuleItemsHtml(
  courseId: string,
  moduleId: ModuleId,
  callback: ModuleItemsCallback,
  per_page = DEFAULT_PAGE_SIZE,
): Promise<void> {
  const moduleItemContainer = document.querySelector(`#context_module_content_${moduleId}`)
  if (!moduleItemContainer) return

  try {
    // Todo here we can start putting up the spinner
    const result = await doFetchApi<ModuleItems>({
      path: `/courses/${courseId}/modules/${moduleId}/items_html?per_page=${per_page}`,
      headers: {
        accept: 'text/html',
      },
    })

    renderResult(moduleItemContainer, result.text)
    callback(moduleId)
  } catch {
    renderError(moduleItemContainer, courseId, moduleId, callback, per_page)
  } finally {
    // Todo here we can remove the spinner
  }
}

// Todo move this file from utils to jquery folder
async function fetchModuleItems(
  courseId: string,
  moduleIds: ModuleId[],
  callback: ModuleItemsCallback,
  per_page = DEFAULT_PAGE_SIZE,
): Promise<void> {
  for (let i = 0; i < moduleIds.length; i += BATCH_SIZE) {
    const batch = moduleIds.slice(i, i + BATCH_SIZE)
    await Promise.all(
      batch.map(moduleId => fetchModuleItemsHtml(courseId, moduleId, callback, per_page))
    )
  }
}

export {
  fetchModuleItemsHtml,
  fetchModuleItems,
  type ModuleId,
  type ModuleItems,
  type ModuleItemsCallback,
}
