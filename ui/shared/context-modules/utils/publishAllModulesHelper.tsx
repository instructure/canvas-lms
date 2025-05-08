/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {CanvasId, FetchedModuleWithItems} from '../react/types'
import {
  renderContextModulesPublishIcon,
  updateModuleItemPublishedState,
  updateModuleItemsPublishedStates,
} from './publishOneModuleHelper'

// calls the batch update api which creates a delayed job and returns
// progress of the work and when it completes is monitored by the
// ContextModulesPublishModal
export function batchUpdateAllModulesApiCall(
  courseId: string | number,
  newPublishedState: boolean | undefined,
  skipContentTags: boolean,
): Promise<any> {
  const path = `/api/v1/courses/${courseId}/modules`

  const event = newPublishedState ? 'publish' : 'unpublish'
  const async = true

  return doFetchApi({
    path,
    method: 'PUT',
    body: {
      module_ids: moduleIds(),
      event,
      skip_content_tags: skipContentTags,
      async,
    },
  })
}

export function fetchAllItemPublishedStates(courseId: string | number, nextLink?: string) {
  return doFetchApi<FetchedModuleWithItems[]>({
    path: nextLink || `/api/v1/courses/${courseId}/modules?include[]=items`,
    method: 'GET',
  }).then(response => {
    const {json, link} = response
    json?.forEach(module => {
      updateModulePublishedState(module.id, module.published, false)
      module.items.forEach(item => {
        updateModuleItemPublishedState(item.id, item.published)
      })
    })
    if (link?.next) {
      fetchAllItemPublishedStates(courseId, link.next.url)
    }
  })
}
// update the state of the modules and items
// based on what the user asked to be done
export function updateModulePendingPublishedStates(isPublishing: boolean): void {
  const completedModuleIds = moduleIds()
  completedModuleIds.forEach(moduleId => {
    exportFuncs.updateModulePublishedState(moduleId, undefined, isPublishing)
    updateModuleItemsPublishedStates(moduleId, undefined, isPublishing)
  })
}

// update the state of a single module and its items
export function updateModulePublishedState(
  moduleId: CanvasId,
  published: boolean | undefined,
  isPublishing: boolean,
) {
  const publishIcon = document.querySelector(
    `#context_module_${moduleId} .module-publish-icon`,
  ) as HTMLElement | null
  if (publishIcon) {
    const courseId = publishIcon.getAttribute('data-course-id') as string
    // Update the new state of the module then we unmount the component to render the newly changed state
    const $publishIcon = $(publishIcon)
    $publishIcon.data('published', !!published)
    renderContextModulesPublishIcon(courseId, moduleId, published, isPublishing)
  }
}

// find all the module ids on the page
// return as an array of numbers
export function moduleIds(): Array<number> {
  const ids = new Set<number>()
  const dataModules = document.querySelectorAll(
    '.context_module[data-module-id]',
  ) as NodeListOf<HTMLElement>
  dataModules.forEach(el => {
    if (el.id === undefined) return

    const id = Number.parseInt(el.id?.replace(/\D/g, '') || '', 10)
    if (!Number.isNaN(id)) ids.add(id)
  })

  return [...ids.values()].filter(Number)
}

// this little trick is so that I can spy on funcions
// calling each other from w/in this module.
const exportFuncs = {
  batchUpdateAllModulesApiCall,
  fetchAllItemPublishedStates,
  updateModulePendingPublishedStates,
  updateModulePublishedState,
  moduleIds,
}

export default exportFuncs
