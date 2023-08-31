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

export function convertFriendlyDatetimeToUTC(date: string | null | undefined): string | undefined {
  if (date) {
    return tz.parse(date, ENV.TIMEZONE)?.toISOString()
  }
}

export function parseModule(element: HTMLElement) {
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
