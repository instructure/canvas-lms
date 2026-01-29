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

import type {LtiPlacement} from './LtiPlacement'
import type {LtiRegistrationWithConfiguration} from './LtiRegistration'
import type {LtiRegistrationUpdateRequest} from './lti_ims_registration/LtiRegistrationUpdateRequest'
import {
  buildPlacementMap,
  calculateAddedPlacements,
  calculateRemovedPlacements,
} from '../pages/tool_details/history/differ'

/**
 * Compares placements between an existing registration and a registration update request.
 *
 * A placement is considered "added" if it's enabled in the update request and either
 * doesn't exist or is disabled in the existing registration.
 *
 * A placement is considered "removed" if it's enabled in the existing registration and
 * either doesn't exist or is disabled in the update request.
 *
 * @param existingRegistration - The current registration configuration
 * @param registrationUpdateRequest - The proposed update request
 * @returns Object containing arrays of added and removed placements
 */
export const diffPlacements = (
  existingRegistration: LtiRegistrationWithConfiguration | null | undefined,
  registrationUpdateRequest: LtiRegistrationUpdateRequest | null | undefined,
): {added: LtiPlacement[]; removed: LtiPlacement[]} => {
  if (!registrationUpdateRequest?.internal_lti_configuration?.placements) {
    return {added: [], removed: []}
  }

  const oldPlacements = buildPlacementMap(existingRegistration?.configuration.placements ?? [])
  const newPlacements = buildPlacementMap(
    registrationUpdateRequest.internal_lti_configuration.placements,
  )

  return {
    added: calculateAddedPlacements(oldPlacements, newPlacements),
    removed: calculateRemovedPlacements(oldPlacements, newPlacements),
  }
}
