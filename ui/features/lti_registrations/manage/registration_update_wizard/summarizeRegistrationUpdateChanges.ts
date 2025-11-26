/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import type {LtiRegistrationUpdateRequest} from '../model/lti_ims_registration/LtiRegistrationUpdateRequest'
import {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_registrations')

export type ChangeInfo = {
  section: string
  detail: string
}

export const summarizeRegistrationUpdateChanges = (
  registrationUpdateRequest: LtiRegistrationUpdateRequest,
  registration: LtiRegistrationWithConfiguration,
) => {
  const changes = {
    added: [] as ChangeInfo[],
    removed: [] as ChangeInfo[],
    noChange: [] as ChangeInfo[],
  }

  // Check permissions/scopes
  const currentScopes = registration.configuration.scopes || []
  const requestedScopes = registrationUpdateRequest.internal_lti_configuration?.scopes || []
  const addedScopes = requestedScopes.filter(scope => !currentScopes.includes(scope))
  const removedScopes = currentScopes.filter(scope => !requestedScopes.includes(scope))

  if (addedScopes.length > 0 || removedScopes.length > 0) {
    if (addedScopes.length > 0) {
      changes.added.push({
        section: I18n.t('Permissions'),
        detail: I18n.t(
          {one: 'Added %{count} new scope', other: 'Added %{count} new scopes'},
          {count: addedScopes.length},
        ),
      })
    }
    if (removedScopes.length > 0) {
      changes.removed.push({
        section: I18n.t('Permissions'),
        detail: I18n.t(
          {one: 'Removed %{count} scope', other: 'Removed %{count} scopes'},
          {count: removedScopes.length},
        ),
      })
    }
  } else {
    changes.noChange.push({
      section: I18n.t('Permissions'),
      detail: '',
    })
  }

  // Check privacy level
  const currentPrivacy = registration.configuration.privacy_level
  const requestedPrivacy = registrationUpdateRequest.internal_lti_configuration.privacy_level

  if (registration.overlay && registration.overlay.data.privacy_level !== undefined) {
    changes.noChange.push({
      section: I18n.t('Privacy Level'),
      detail: '',
    })
  } else if (requestedPrivacy !== currentPrivacy && requestedPrivacy !== undefined) {
    changes.added.push({
      section: I18n.t('Privacy Level'),
      detail: I18n.t('Changed to %{level}', {level: requestedPrivacy}),
    })
  } else {
    changes.noChange.push({
      section: I18n.t('Privacy Level'),
      detail: '',
    })
  }

  // Check placements
  const currentPlacements = registration.configuration.placements.map(p => p.placement) || []
  const requestedPlacementNames =
    registrationUpdateRequest.internal_lti_configuration.placements.map(p => p.placement) || []
  const addedPlacements = requestedPlacementNames.filter(p => !currentPlacements.includes(p))
  const removedPlacements = currentPlacements.filter(p => !requestedPlacementNames.includes(p))

  if (addedPlacements.length > 0 || removedPlacements.length > 0) {
    if (addedPlacements.length > 0) {
      changes.added.push({
        section: I18n.t('Placements'),
        detail: I18n.t(
          {one: 'Added %{count} placement', other: 'Added %{count} placements'},
          {count: addedPlacements.length},
        ),
      })
    }
    if (removedPlacements.length > 0) {
      changes.removed.push({
        section: I18n.t('Placements'),
        detail: I18n.t(
          {one: 'Removed %{count} placement', other: 'Removed %{count} placements'},
          {count: removedPlacements.length},
        ),
      })
    }
  } else {
    changes.noChange.push({
      section: I18n.t('Placements'),
      detail: '',
    })
  }

  // Check naming (title/description)
  const currentTitle = registration.name || registration.configuration.title
  const requestedTitle = registrationUpdateRequest.internal_lti_configuration?.title

  if (requestedTitle && requestedTitle !== currentTitle) {
    changes.added.push({
      section: I18n.t('Naming'),
      detail: I18n.t('Updated app name'),
    })
  } else {
    changes.noChange.push({
      section: I18n.t('Naming'),
      detail: '',
    })
  }

  // Check icon changes - compare update request against original registration
  // Ignore placements that have icon changes in the overlay (user modifications)
  let hasIconChanges = false

  const originalPlacementConfigs = registration.configuration.placements || []
  const requestedPlacementConfigs =
    registrationUpdateRequest.internal_lti_configuration?.placements || []

  // Contains placements with icon overrides in the overlay
  const overlayIconPlacements = Object.entries(registration.overlay?.data?.placements || {}).reduce(
    (acc, [pl, plConfig]) => {
      return plConfig.icon_url ? acc.concat([pl]) : acc
    },
    [] as Array<string>,
  )

  for (const requestedPlacementConfig of requestedPlacementConfigs) {
    const placementName = requestedPlacementConfig.placement

    // Skip if this placement has an icon override in the overlay
    if (overlayIconPlacements.includes(placementName)) {
      continue
    }

    const originalPlacementConfig = originalPlacementConfigs.find(
      p => p.placement === placementName,
    )

    // Skip if this is a newly added placement (not in original registration)
    // Icon changes for new placements are part of the new placement, not a change
    if (!originalPlacementConfig) {
      continue
    }

    const originalIconUrl = originalPlacementConfig.icon_url
    const requestedIconUrl = requestedPlacementConfig.icon_url

    if (originalIconUrl !== requestedIconUrl) {
      hasIconChanges = true
      break
    }
  }

  if (hasIconChanges) {
    changes.added.push({
      section: I18n.t('Icon'),
      detail: I18n.t('Icon settings updated'),
    })
  } else {
    changes.noChange.push({
      section: I18n.t('Icon'),
      detail: '',
    })
  }

  return changes
}
