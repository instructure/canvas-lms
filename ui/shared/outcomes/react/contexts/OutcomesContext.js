/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {createContext} from 'react'

const OutcomesContext = createContext({})

export const ROOT_GROUP_ID = '0'
export const ACCOUNT_GROUP_ID = '-1'

export const getContext = isMobileView => {
  const [snakeContextType, contextId] = ENV.context_asset_string.split('_')
  const contextType = snakeContextType === 'course' ? 'Course' : 'Account'
  const rootOutcomeGroup = ENV.ROOT_OUTCOME_GROUP
  const friendlyDescriptionFF = ENV.OUTCOMES_FRIENDLY_DESCRIPTION
  const canManage = ENV.PERMISSIONS?.manage_outcomes
  const canImport = ENV.PERMISSIONS?.import_outcomes
  const isAdmin = ENV.current_user_is_admin
  const isStudent = ENV.current_user_is_student
  const globalRootId = ENV.GLOBAL_ROOT_OUTCOME_GROUP_ID?.toString()
  const treeBrowserRootGroupId = ROOT_GROUP_ID
  const treeBrowserAccountGroupId = ACCOUNT_GROUP_ID
  const rootIds = [globalRootId, treeBrowserAccountGroupId, treeBrowserRootGroupId]
  const accountLevelMasteryScalesFF = ENV.ACCOUNT_LEVEL_MASTERY_SCALES
  const outcomeAllowAverageCalculationFF = ENV.OUTCOME_AVERAGE_CALCULATION
  const menuOptionForOutcomeDetailsPageFF = ENV.MENU_OPTION_FOR_OUTCOME_DETAILS_PAGE
  const archiveOutcomesFF = ENV.ARCHIVE_OUTCOMES

  return {
    env: {
      contextType,
      contextId,
      rootOutcomeGroup,
      friendlyDescriptionFF,
      isMobileView,
      canManage,
      canImport,
      isAdmin,
      isStudent,
      globalRootId,
      treeBrowserRootGroupId,
      treeBrowserAccountGroupId,
      rootIds,
      accountLevelMasteryScalesFF,
      outcomeAllowAverageCalculationFF,
      menuOptionForOutcomeDetailsPageFF,
      archiveOutcomesFF,
    },
  }
}

export default OutcomesContext
