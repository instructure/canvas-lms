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
import React from 'react'
import ReactDOM from 'react-dom'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import ContextModulesPublishIcon from '../react/ContextModulesPublishIcon'
import {updateModuleItem, itemContentKey} from '../jquery/utils'
import RelockModulesDialog from '@canvas/relock-modules-dialog'
import type {
  CanvasId,
  DoFetchModuleResponse,
  DoFetchModuleItemsResponse,
  KeyedModuleItems,
  ModuleItem,
  ModuleItemStateData,
} from '../react/types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('context_modules_utils_publishmoduleitemhelper')

export function publishModule(courseId: CanvasId, moduleId: CanvasId, skipItems: boolean) {
  const loadingMessage = skipItems
    ? I18n.t('Publishing module')
    : I18n.t('Publishing module and items')
  const successMessage = skipItems
    ? I18n.t('Module published')
    : I18n.t('Module and items published')

  exportFuncs.batchUpdateOneModuleApiCall(
    courseId,
    moduleId,
    true,
    skipItems,
    loadingMessage,
    successMessage
  )
}

export function unpublishModule(courseId: CanvasId, moduleId: CanvasId, skipItems: boolean) {
  const loadingMessage = skipItems
    ? I18n.t('Unpublishing module')
    : I18n.t('Unpublishing module and items')
  const successMessage = skipItems
    ? I18n.t('Module unpublished')
    : I18n.t('Module and items unpublished')
  exportFuncs.batchUpdateOneModuleApiCall(
    courseId,
    moduleId,
    false,
    skipItems,
    loadingMessage,
    successMessage
  )
}

export function batchUpdateOneModuleApiCall(
  courseId: CanvasId,
  moduleId: CanvasId,
  newPublishedState: boolean,
  skipContentTags: boolean,
  loadingMessage: string,
  successMessage: string
) {
  const path = `/api/v1/courses/${courseId}/modules/${moduleId}`

  const published = getModulePublishState(moduleId)
  exportFuncs.renderContextModulesPublishIcon(courseId, moduleId, published, true, loadingMessage)
  exportFuncs.updateModuleItemsPublishedStates(moduleId, undefined, true)
  exportFuncs.disableContextModulesPublishMenu(true)
  const relockModulesDialog = new RelockModulesDialog()
  let published_result: boolean
  return doFetchApi({
    path,
    method: 'PUT',
    body: {
      module: {
        published: newPublishedState,
        skip_content_tags: skipContentTags,
      },
    },
  })
    .then((result: DoFetchModuleResponse) => {
      if (result.json.publish_warning) {
        showFlashAlert({
          message: I18n.t('Some module items could not be published'),
          type: 'warning',
          err: null,
        })
      }
      relockModulesDialog.renderIfNeeded(result.json)

      return exportFuncs
        .fetchModuleItemPublishedState(courseId, moduleId)
        .then(() => {
          published_result = result.json.published

          showFlashAlert({
            message: successMessage,
            type: 'success',
            err: null,
            srOnly: true,
          })
        })
        .finally(() => {
          exportFuncs.disableContextModulesPublishMenu(false)
          exportFuncs.renderContextModulesPublishIcon(
            courseId,
            moduleId,
            published_result,
            false,
            loadingMessage
          )
        })
    })
    .catch((error: Error) => {
      showFlashAlert({
        message: I18n.t('There was an error while saving your changes'),
        err: error,
        type: 'error',
      })
      exportFuncs.updateModuleItemsPublishedStates(moduleId, undefined, false)
    })
}

export const fetchModuleItemPublishedState = (
  courseId: CanvasId,
  moduleId: CanvasId,
  nextLink?: string
) => {
  return doFetchApi({
    path: nextLink || `/api/v1/courses/${courseId}/modules/${moduleId}/items`,
    method: 'GET',
  })
    .then((response: DoFetchModuleItemsResponse) => {
      const {json, link} = response
      const moduleItems = exportFuncs.getAllModuleItems()
      json.forEach((item: any) => {
        exportFuncs.updateModuleItemPublishedState(item.id, item.published, false, moduleItems)
      })
      if (link?.next) {
        return exportFuncs.fetchModuleItemPublishedState(courseId, moduleId, link.next.url)
      } else {
        return response
      }
    })
    .catch((error: Error) =>
      showFlashAlert({
        message: I18n.t('There was an error while saving your changes'),
        type: 'error',
        err: error,
      })
    )
}

// collect all the module items, indexed by their key
// which is the underlying learning object's asset_string
// (e.g. assignment_17 or wiki_page_5)
export function getAllModuleItems(): KeyedModuleItems {
  const moduleItems: KeyedModuleItems = {}
  document.querySelectorAll('#context_modules .publish-icon').forEach(element => {
    const $publishIcon = $(element)
    const data = $publishIcon.data()
    const view = data.view
    if (view) {
      const key = itemContentKey(view.model) as string
      if (moduleItems[key]) {
        moduleItems[key].push({view, model: view.model})
      } else {
        moduleItems[key] = [{view, model: view.model}]
      }
    }
  })
  return moduleItems
}

// update the state of all the module items' pub/unpub state
export function updateModuleItemsPublishedStates(
  moduleId: CanvasId,
  published: boolean | undefined,
  isPublishing: boolean
) {
  const moduleItems = exportFuncs.getAllModuleItems()

  // update all the module items in the module being updated,
  // plus module items that are also in other modules
  document
    .querySelectorAll(`#context_module_content_${moduleId} .publish-icon`)
    .forEach(element => {
      exportFuncs.updateModuleItemPublishedState(
        element as HTMLElement,
        published,
        isPublishing,
        moduleItems
      )
    })
}

// update an  item's pub/sub state
export function updateModuleItemPublishedState(
  itemIdOrElem: string | HTMLElement,
  isPublished: boolean | undefined,
  isPublishing?: boolean,
  allModuleItems?: KeyedModuleItems | undefined
) {
  const publishIcon =
    typeof itemIdOrElem === 'string'
      ? document.querySelector(`#context_module_item_${itemIdOrElem} .publish-icon`)
      : itemIdOrElem

  if (publishIcon) {
    const $publishIcon = $(publishIcon)
    const data = $publishIcon.data()
    const view = data.view
    const updatedAttrs: ModuleItemStateData = {
      bulkPublishInFlight: isPublishing,
    }
    if (!isPublishing && typeof isPublished === 'boolean') updatedAttrs.published = isPublished
    const key = itemContentKey(view.model) as string
    const items = allModuleItems?.[key] || [{view, model: view.model}]
    updateModuleItem({[key]: items}, updatedAttrs, view.model)
    if (!isPublishing && typeof isPublished === 'boolean')
      updateModuleItemRowsPublishStates(items, isPublished)
  }
}

// published items have a green bar on their leading edge.
// make that happen for all the matching items
// the code in PublishButton.prototype.renderState handles it for a single item
// but doesn't work for items that are in multiple modules during bulk publish
export function updateModuleItemRowsPublishStates(items: ModuleItem[], isPublished: boolean): void {
  items.forEach(item => {
    const itemId = item.model.attributes.module_item_id
    const itemRow = document.querySelector(`#context_module_item_${itemId}`) as HTMLElement | null
    if (itemRow) {
      itemRow.querySelector('.ig-row')?.classList.toggle('ig-published', isPublished)
    }
  })
}

export function renderContextModulesPublishIcon(
  courseId: string | number,
  moduleId: string | number,
  published: boolean | undefined,
  isPublishing: boolean,
  loadingMessage?: string
) {
  const publishIcon = findModulePublishIcon(moduleId)
  if (publishIcon) {
    const moduleName =
      publishIcon?.closest('.context_module')?.querySelector('.ig-header-title')?.textContent ||
      `module${moduleId}`
    ReactDOM.render(
      <ContextModulesPublishIcon
        courseId={courseId}
        moduleId={moduleId}
        moduleName={moduleName}
        isPublishing={isPublishing}
        published={published}
        loadingMessage={loadingMessage}
      />,
      publishIcon
    )
  }
}

function findModulePublishIcon(moduleId: CanvasId) {
  return document.querySelector(`#context_module_${moduleId} .module-publish-icon`)
}

function getModulePublishState(moduleId: CanvasId) {
  const el = findModulePublishIcon(moduleId)
  return el ? $(el).data('published') : false
}

// this has to be in here rather than publishModulesHelper
// to avoid a circular dependency
export function disableContextModulesPublishMenu(disabled: boolean) {
  // I'm not crazy about leaning on a global, but it's actually
  // the cleanest way to go about disabling the Publish All button
  window.modules?.updatePublishMenuDisabledState(disabled)
}

// this little trick is so that I can spy on funcions
// calling each other from w/in this module.
const exportFuncs = {
  publishModule,
  unpublishModule,
  batchUpdateOneModuleApiCall,
  fetchModuleItemPublishedState,
  getAllModuleItems,
  updateModuleItemsPublishedStates,
  updateModuleItemPublishedState,
  renderContextModulesPublishIcon,
  disableContextModulesPublishMenu,
}

export default exportFuncs
