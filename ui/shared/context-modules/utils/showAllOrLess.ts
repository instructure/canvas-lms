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

import {DEFAULT_PAGE_SIZE} from './ModuleItemsLazyLoader'
import {type ModuleId} from './ModuleItemLoadingData'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modulespublic')

type AllOrLess = 'all' | 'less' | 'none' | 'loading'

const MODULE_EXPAND_AND_LOAD_ALL = 'module-expand-and-load-all'
const MODULE_LOAD_ALL = 'module-load-all'
const MODULE_LOAD_FIRST_PAGE = 'module-load-first-page'

function moduleFromId(moduleId: ModuleId): HTMLElement {
  return document.querySelector(`#context_module_${moduleId}`) as HTMLElement
}

function isModuleLoading(module: HTMLElement) {
  return !!module.querySelector('.module-spinner-container')
}

function isModuleCurrentPageEmpty(module: HTMLElement) {
  return module.querySelectorAll('.context_module_item').length === 0
}
function isModulePaginated(module: HTMLElement) {
  return !!module.querySelector(`[data-testid="module-${module.dataset.moduleId}-pagination"]`)
}

function isModuleCollapsed(module: HTMLElement) {
  return module.classList.contains('collapsed_module')
}

function isModuleSelectedByTEACHER_MODULE_SELECTION(module: HTMLElement) {
  if (ENV.IS_STUDENT) return false
  if (!ENV.MODULE_FEATURES?.TEACHER_MODULE_SELECTION) return false

  const moduleId = (document.getElementById('show_teacher_only_module_id') as HTMLSelectElement)
    ?.value
  if (moduleId && moduleId === module.dataset.moduleId) {
    return true
  }
  return false
}

function itemCount(module: HTMLElement): number {
  return module.querySelectorAll('.context_module_item').length
}

function shouldShowAllOrLess(module: HTMLElement): AllOrLess {
  if (isModuleSelectedByTEACHER_MODULE_SELECTION(module)) {
    return 'none'
  }
  if (isModuleCollapsed(module)) {
    return 'none'
  } else {
    if (isModuleLoading(module)) {
      return 'loading'
    }
    if (isModulePaginated(module)) {
      return 'all'
    }
    if (itemCount(module) > DEFAULT_PAGE_SIZE) {
      return 'less'
    }
  }
  return 'none'
}

function addOrRemoveButton(module: HTMLElement) {
  const shouldShow = shouldShowAllOrLess(module)

  let button = module.querySelector('.show-all-or-less-button.ui-button') as HTMLElement
  const totalItems = (module.querySelector('.content ul') as HTMLElement)?.dataset?.totalItems || ''

  if (shouldShow === 'none') {
    if (button) {
      button.removeEventListener('click', handleShowAllOrLessClick)
      button.removeEventListener('keydown', buttonKeyDown)
      button.remove()
    }
    return
  }

  if (!button) {
    button = document.createElement('button')
    button.className = 'show-all-or-less-button ui-button'
    button.dataset.moduleId = module.dataset.moduleId
    button.addEventListener('click', handleShowAllOrLessClick)
    button.addEventListener('keydown', buttonKeyDown)
    const reqMsg = module.querySelector('.header .ig-header-admin .requirements_message')
    reqMsg?.after(button)
  }

  if (shouldShow === 'all') {
    button.classList.add('show-all')
    button.classList.remove('show-less')
    if (totalItems) {
      button.textContent = I18n.t('Show All (%{totalItems})', {totalItems: totalItems})
    } else {
      button.textContent = I18n.t('Show All')
    }
  } else {
    button.classList.add('show-less')
    button.classList.remove('show-all')
    button.textContent = I18n.t('Show Less')
  }
}

function maybeShowAllOrLess(moduleId: ModuleId) {
  const module = moduleFromId(moduleId)
  if (!module) return

  const shouldShow = shouldShowAllOrLess(module)
  if (shouldShow === 'loading') {
    requestAnimationFrame(() => {
      maybeShowAllOrLess(moduleId)
    })
    return
  }
  addOrRemoveButton(module)
}

function addShowAllOrLess(moduleId: ModuleId) {
  const module = moduleFromId(moduleId)
  if (!module) return

  maybeShowAllOrLess(moduleId)
}

function handleShowAllOrLessClick(event: Event) {
  const moduleId: string | null = (event.target as HTMLElement).getAttribute('data-module-id')
  if (!moduleId) return

  const module = moduleFromId(moduleId)
  if (!module) return

  const button = module.querySelector('.show-all-or-less-button') as HTMLElement
  if (!button) return

  if (button.classList.contains('show-all')) {
    if (isModuleCollapsed(module)) {
      expandModuleAndLoadAll(moduleId)
    } else {
      loadAll(moduleId)
    }
  } else {
    loadFirstPage(moduleId)
  }
}

function maybeExpandAndLoadAll(moduleId: ModuleId) {
  const module = moduleFromId(moduleId)
  if (!module) return

  if (isModuleCollapsed(module)) {
    expandModuleAndLoadAll(moduleId)
  } else if (isModulePaginated(module)) {
    loadAll(moduleId)
  }
}

function expandModuleAndLoadAll(moduleId: ModuleId) {
  const event = new CustomEvent(MODULE_EXPAND_AND_LOAD_ALL, {
    detail: {moduleId, allPages: true},
  })
  document.dispatchEvent(event)
}

function loadAll(moduleId: ModuleId) {
  const event = new CustomEvent(MODULE_LOAD_ALL, {detail: {moduleId}})
  document.dispatchEvent(event)
}

function loadFirstPage(moduleId: ModuleId) {
  const event = new CustomEvent(MODULE_LOAD_FIRST_PAGE, {detail: {moduleId}})
  document.dispatchEvent(event)
}

function buttonKeyDown(event: KeyboardEvent) {
  if (event.key === ' ') {
    ;(event.target as HTMLElement)?.click()
  }
}

export {
  addShowAllOrLess,
  shouldShowAllOrLess,
  itemCount,
  isModuleCurrentPageEmpty,
  isModuleCollapsed,
  isModulePaginated,
  isModuleLoading,
  isModuleSelectedByTEACHER_MODULE_SELECTION,
  expandModuleAndLoadAll,
  loadAll,
  loadFirstPage,
  maybeExpandAndLoadAll,
  MODULE_EXPAND_AND_LOAD_ALL,
  MODULE_LOAD_ALL,
  MODULE_LOAD_FIRST_PAGE,
  type AllOrLess,
}
