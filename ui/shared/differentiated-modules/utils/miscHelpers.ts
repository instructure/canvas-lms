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

export function calculatePanelHeight(withinTabs: boolean): string {
  let headerHeight = 79.5
  headerHeight += withinTabs ? 48 : 0 // height of the tab selector
  return `calc(100vh - ${headerHeight}px)`
}

export function convertFriendlyDatetimeToUTC(date: string | null | undefined): string | undefined {
  if (date) {
    return tz.parse(date, ENV.TIMEZONE)?.toISOString()
  }
}

export function convertModuleSettingsForApi(moduleSettings: SettingsPanelState) {
  return {
    context_module: {
      name: moduleSettings.moduleName,
      unlock_at: moduleSettings.lockUntilChecked ? moduleSettings.unlockAt : null,
      prerequisites: moduleSettings.prerequisites
        .filter(prerequisite => prerequisite.id !== '-1')
        .map(prerequisite => `module_${prerequisite.id}`)
        .join(','),
    },
  }
}
