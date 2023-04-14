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
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('context_modules_utils_publishmoduleitemhelper')

interface ModuleItemAttributes {
  module_item_id: number
}

interface ModuleItemModel {
  attributes: ModuleItemAttributes
}

interface ModuleItemView {
  model: ModuleItemModel
}

interface ModuleItem {
  model: ModuleItemModel
  view: ModuleItemView
}

interface KeyedModuleItems {
  [key: string]: ModuleItem[]
}

type moduleItemStateData = {
  published?: boolean
  bulkPublishInFlight?: boolean
}

export function publishModule(courseId, moduleId, skipItems) {
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

export function unpublishModule(courseId, moduleId) {
  const loadingMessage = I18n.t('Unpublishing module and items')
  const successMessage = I18n.t('Module and items unpublished')
  exportFuncs.batchUpdateOneModuleApiCall(
    courseId,
    moduleId,
    false,
    false,
    loadingMessage,
    successMessage
  )
}

export function batchUpdateOneModuleApiCall(
  courseId: number,
  moduleId: number,
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
    .then(result => {
      exportFuncs.fetchModuleItemPublishedState(courseId, moduleId)
      exportFuncs.renderContextModulesPublishIcon(
        courseId,
        moduleId,
        result.json.published,
        false,
        loadingMessage
      )
      if (skipContentTags) {
        exportFuncs.updateModuleItemsPublishedStates(moduleId, undefined, false)
      } else {
        exportFuncs.updateModuleItemsPublishedStates(moduleId, result.json.published, false)
      }
      showFlashAlert({
        message: successMessage,
        type: 'success',
        err: null,
        srOnly: true,
      })
    })
    .catch(error => {
      showFlashAlert({
        message: I18n.t('There was an error while saving your changes'),
        err: error,
        type: 'error',
      })
      exportFuncs.updateModuleItemsPublishedStates(moduleId, undefined, false)
    })
    .finally(() => {
      exportFuncs.disableContextModulesPublishMenu(false)
    })
}

export const fetchModuleItemPublishedState = (courseId, moduleId, nextLink?: string) => {
  doFetchApi({
    path: nextLink || `/api/v1/courses/${courseId}/modules/${moduleId}/items`,
    method: 'GET',
  })
    .then(response => {
      const {json, link} = response
      json.forEach((item: any) => {
        exportFuncs.updateModuleItemPublishedState(item.id, item.published)
      })
      if (link?.next) {
        exportFuncs.fetchModuleItemPublishedState(courseId, moduleId, link.next.url)
      }
    })
    .catch(error =>
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
  const moduleItems = {}
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
  moduleId: number,
  published: boolean | undefined,
  isPublishing: boolean
) {
  const moduleItems = exportFuncs.getAllModuleItems()

  // update all the module items in the module being updated,
  // plus module items that are also in other modules
  document
    .querySelectorAll(`#context_module_content_${moduleId} .publish-icon`)
    .forEach(element => {
      const $publishIcon = $(element)
      const data = $publishIcon.data()
      exportFuncs.updateModuleItemPublishedState(
        data.moduleItemId,
        published,
        isPublishing,
        moduleItems
      )
    })
}

// update an  item's pub/sub state
export function updateModuleItemPublishedState(
  itemId: string,
  isPublished: boolean | undefined,
  isPublishing?: boolean,
  allModuleItems?: KeyedModuleItems | undefined
) {
  const publishIcon = document.querySelector(`#context_module_item_${itemId} .publish-icon`)
  if (publishIcon) {
    const $publishIcon = $(publishIcon)
    const data = $publishIcon.data()
    const view = data.view
    const updatedAttrs: moduleItemStateData = {
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
  courseId,
  moduleId,
  published,
  isPublishing,
  loadingMessage
) {
  const publishIcon = findModulePublishIcon(moduleId)
  ReactDOM.render(
    <ContextModulesPublishIcon
      courseId={courseId}
      moduleId={moduleId}
      isPublishing={isPublishing}
      published={published}
      loadingMessage={loadingMessage}
    />,
    publishIcon
  )
}

function findModulePublishIcon(moduleId) {
  return document.querySelector(`.module-publish-icon[data-module-id="${moduleId}"]`)
}

function getModulePublishState(moduleId) {
  const el = findModulePublishIcon(moduleId)
  return el ? $(el).data('published') : false
}

// this has to be in here rather than publishModulesHelper
// to avoid a circular dependency
export function disableContextModulesPublishMenu(disabled) {
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
