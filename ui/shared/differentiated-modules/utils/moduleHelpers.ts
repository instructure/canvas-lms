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

import tz from '@canvas/timezone'
import type {SettingsPanelState} from '../react/settingsReducer'
import {updateModulePublishedState} from '@canvas/context-modules/utils/publishAllModulesHelper'
import {datetimeString} from '@canvas/datetime/date-functions'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export function convertFriendlyDatetimeToUTC(date: string | null | undefined): string | undefined {
  if (date) {
    return tz.parse(date, ENV.TIMEZONE)?.toISOString()
  }
}

export function parseModule(element: HTMLDivElement) {
  const moduleId = element.getAttribute('data-module-id')
  const moduleName = element.querySelector('.name')?.getAttribute('title') ?? ''
  const unlockAt = convertFriendlyDatetimeToUTC(element.querySelector('.unlock_at')?.textContent)
  const requireSequentialProgress = !!element.querySelector('.require_sequential_progress')
    ?.textContent
  const publishFinalGrade = !!element.querySelector('.publish_final_grade')?.textContent

  return {
    moduleId,
    moduleName,
    unlockAt,
    requireSequentialProgress,
    publishFinalGrade,
  }
}

export function convertModuleSettingsForApi(moduleSettings: SettingsPanelState) {
  return {
    context_module: {
      name: moduleSettings.moduleName,
      unlock_at: moduleSettings.lockUntilChecked ? moduleSettings.unlockAt : null,
    },
  }
}

export function updateModuleUI(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  ;[updateName, updateUnlockTime].forEach(fn => fn(moduleElement, moduleSettings))
}

function updateName(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  moduleElement.setAttribute('aria-label', moduleSettings.moduleName)

  const screenreaderOnlyElement = moduleElement.querySelector('.screenreader-only')
  if (screenreaderOnlyElement) {
    screenreaderOnlyElement.textContent = moduleSettings.moduleName
  }

  moduleElement.querySelectorAll('.name').forEach(nameElement => {
    nameElement.setAttribute('title', moduleSettings.moduleName)
    nameElement.textContent = moduleSettings.moduleName
  })

  moduleElement.querySelectorAll('.collapse_module_link, .expand_module_link').forEach(button => {
    button.setAttribute('title', moduleSettings.moduleName)
    button.setAttribute(
      'aria-label',
      I18n.t('%{name} toggle module visibility', {name: moduleSettings.moduleName})
    )
  })

  const addModuleItemButton = moduleElement.querySelector('.add_module_item_link')
  if (addModuleItemButton) {
    const message = I18n.t('Add Content to %{name}', {name: moduleSettings.moduleName})
    addModuleItemButton.setAttribute('aria-label', message)

    const innerScreenreaderOnlyElement = addModuleItemButton.querySelector('.screenreader-only')
    if (innerScreenreaderOnlyElement) {
      innerScreenreaderOnlyElement.textContent = message
    }
  }

  const kebabMenuButton = moduleElement.querySelector('.Button--icon-action.al-trigger')
  if (kebabMenuButton) {
    kebabMenuButton.setAttribute(
      'aria-label',
      I18n.t('Manage %{name}', {name: moduleSettings.moduleName})
    )
  }

  const duplicateButton = moduleElement.querySelector('.duplicate_module_link')
  if (duplicateButton) {
    duplicateButton.setAttribute(
      'aria-label',
      I18n.t('Duplicate %{name}', {name: moduleSettings.moduleName})
    )
  }

  const moduleId = moduleElement.getAttribute('data-module-id')
  if (moduleId) {
    const published = moduleElement.getAttribute('data-workflow-state') === 'active'
    updateModulePublishedState(parseInt(moduleId, 10), published, false)
  }
}

function updateUnlockTime(moduleElement: HTMLDivElement, moduleSettings: SettingsPanelState) {
  const friendlyDatetime = moduleSettings.lockUntilChecked
    ? datetimeString(moduleSettings.unlockAt)
    : ''

  const unlockAtElement = moduleElement.querySelector('.unlock_at')
  if (unlockAtElement) {
    unlockAtElement.textContent = friendlyDatetime
  }

  const displayedUnlockAtElement = moduleElement.querySelector('.displayed_unlock_at')
  if (displayedUnlockAtElement) {
    displayedUnlockAtElement.textContent = friendlyDatetime
    displayedUnlockAtElement.setAttribute('data-html-tooltip-title', friendlyDatetime)
  }

  const unlockDetailsElement = moduleElement.querySelector('.unlock_details') as HTMLDivElement
  if (unlockDetailsElement) {
    // User has selected a lock date and that date is in the future
    if (moduleSettings.lockUntilChecked && new Date(moduleSettings.unlockAt) > new Date()) {
      unlockDetailsElement.style.display = ''
    } else {
      unlockDetailsElement.style.display = 'none'
    }
  }
}
