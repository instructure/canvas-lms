/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

type Requirement = {
  id: string
  name: string
  resource: string
  type: string
}

type Prerequisite = {
  id: string
  name: string
}

type ModuleState = {
  lockUntilChecked?: boolean
  prerequisites?: Prerequisite[]
  requirements?: Requirement[]
  unlockAt?: string
}

/**
 * Main function to determine if a relock warning should be shown
 * This mirrors the server-side relock_warning_check logic
 * for changed settings only
 */

export function shouldShowRelockWarning(
  newState: ModuleState,
  currentState: ModuleState,
  published: boolean,
) {
  // Don't show warning if course or module isn't available
  if (!ENV.CONTEXT_IS_AVAILABLE || !published) {
    return false
  }

  // Check if we're adding completion requirements
  // do not warn if only removing requirements
  if (newState.requirements && newState.requirements.length > 0) {
    const currentRequirements = currentState.requirements || []

    const hasNewRequirements = newState.requirements.some(newReq => {
      return !currentRequirements.some(
        currentReq =>
          currentReq.id === newReq.id &&
          currentReq.resource === newReq.resource &&
          currentReq.type === newReq.type,
      )
    })

    if (hasNewRequirements) {
      return true
    }
  }

  // Check if we're adding prerequisites
  // do not warn if only removing prerequisites
  if (newState.prerequisites && newState.prerequisites.length > 0) {
    const currentPrerequisites = currentState.prerequisites || []

    const hasNewPrerequisites = newState.prerequisites.some(newPrereq => {
      return !currentPrerequisites.some(currentPrereq => currentPrereq.id === newPrereq.id)
    })

    if (hasNewPrerequisites) {
      return true
    }
  }

  // Check if we're adding an unlock date
  if (newState.unlockAt && !currentState.lockUntilChecked) {
    return true
  }

  return false
}
