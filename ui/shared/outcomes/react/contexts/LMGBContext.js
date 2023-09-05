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

import {createContext} from 'react'

const LMGBContext = createContext({})

export const getLMGBContext = () => {
  const gradebookOptions = ENV?.GRADEBOOK_OPTIONS
  const contextURL = gradebookOptions?.context_url
  const outcomeProficiency = gradebookOptions?.outcome_proficiency
  const accountLevelMasteryScalesFF = gradebookOptions?.ACCOUNT_LEVEL_MASTERY_SCALES
  const outcomesFriendlyDescriptionFF = gradebookOptions?.OUTCOMES_FRIENDLY_DESCRIPTION

  return {
    env: {
      contextURL,
      outcomeProficiency,
      accountLevelMasteryScalesFF,
      outcomesFriendlyDescriptionFF,
    },
  }
}

export default LMGBContext
