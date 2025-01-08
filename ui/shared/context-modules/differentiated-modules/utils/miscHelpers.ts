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

import * as tz from '@instructure/moment-utils'
import type {SettingsPanelState} from '../react/settingsReducer'
import type {Requirement} from '../react/types'

export function calculatePanelHeight(withinTabs: boolean): string {
  let headerHeight = 79.5
  headerHeight += withinTabs ? 48 : 0 // height of the tab selector
  headerHeight += calculateMasqueradeHeight()
  return `calc(100vh - ${headerHeight}px)`
}

export function calculateMasqueradeHeight(): number {
  return document.body.className.match(/\bis-masquerading-or-student-view\b/) ? 52 : 0
}

export function convertFriendlyDatetimeToUTC(date: string | null | undefined): string | undefined {
  if (date) {
    return tz.parse(date, ENV.TIMEZONE)?.toISOString()
  }
}

export function convertModuleSettingsForApi(moduleSettings: SettingsPanelState) {
  const typeMap: Record<Requirement['type'], string> = {
    view: 'must_view',
    mark: 'must_mark_done',
    submit: 'must_submit',
    score: 'min_score',
    percentage: 'min_percentage',
    contribute: 'must_contribute',
  }

  type ContextModule = {
    name?: string
    unlock_at: string | null
    prerequisites: string
    completion_requirements: Record<string, Record<string, string>>
    requirement_count: string
    require_sequential_progress: boolean
    publish_final_grade: boolean
  }

  const context_module: ContextModule = {
    unlock_at: moduleSettings.lockUntilChecked ? moduleSettings.unlockAt : null,
      prerequisites: moduleSettings.prerequisites
        .map(prerequisite => `module_${prerequisite.id}`)
        .join(','),
      completion_requirements: moduleSettings.requirements.reduce((requirements, requirement) => {
        requirements[requirement.id] = {
          type: typeMap[requirement.type],
          min_score: requirement.type === 'score' ? requirement.minimumScore : '',
          min_percentage: requirement.type === 'percentage' ? requirement.minimumScore : '',
        }
        return requirements
      }, {} as Record<string, Record<string, string>>),
      requirement_count: moduleSettings.requirementCount === 'one' ? '1' : '',
      require_sequential_progress:
        moduleSettings.requirementCount === 'all' && moduleSettings.requireSequentialProgress,
      publish_final_grade: moduleSettings.publishFinalGrade,
  }

  // do not include module name if it was not modified on the panel
  if (moduleSettings.moduleNameDirty) context_module.name = moduleSettings.moduleName

  return {context_module}
}

export function requirementTypesForResource(requirement: Requirement): Requirement['type'][] {
  switch (requirement.resource) {
    case 'assignment':
      return ['view', 'mark', 'submit', 'score']
    case 'quiz':
      return ['view', 'submit', 'score']
    case 'file':
      return ['view']
    case 'page':
      return ['view', 'mark', 'contribute']
    case 'discussion': {
      return requirement.graded ? ['view', 'contribute', 'submit', 'score'] : ['view', 'contribute']
    }
    case 'externalUrl':
      return ['view']
    case 'externalTool':
      return ['view']
  }
}
