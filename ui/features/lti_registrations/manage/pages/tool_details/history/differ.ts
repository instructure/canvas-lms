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

import {isEqual} from 'es-toolkit/compat'
import {InternalLtiConfiguration} from '../../../model/internal_lti_configuration/InternalLtiConfiguration'
import {InternalPlacementConfiguration} from '../../../model/internal_lti_configuration/placement_configuration/InternalPlacementConfiguration'
import {InternalBaseLaunchSettings} from '../../../model/internal_lti_configuration/InternalBaseLaunchSettings'
import {
  AvailabilityChangeHistoryEntry,
  ConfigChangeHistoryEntry,
  isEntryForConfigChange,
  LtiRegistrationHistoryEntry,
  LtiRegistrationTrackedAttributes,
  LtiContextControlTrackedAttributes,
} from '../../../model/LtiRegistrationHistoryEntry'
import {LtiPlacement} from '../../../model/LtiPlacement'
import {LtiContextControlId} from '../../../model/LtiContextControl'
import type {LtiDeployment} from '../../../model/LtiDeployment'
import type {LtiContextControl} from '../../../model/LtiContextControl'

/**
 * Recursively traverses a value and returns null if it's "empty", otherwise returns the value.
 *
 * A value is considered empty if:
 * - Array: length is 0 or all elements are empty
 * - Map: size is 0 or all values are empty
 * - Object: has no keys or all values are empty
 * - String: trimmed length is 0
 * - Other: falsy value
 *
 * This is used to clean up diff objects by removing nested structures that contain no meaningful changes.
 *
 * @param value - The value to check for emptiness
 * @returns The original value if non-empty, null if empty
 */
const deepCheckEmpty = <T>(value: T): T | null => {
  if (value instanceof Array) {
    if (value.length > 0 && value.some(v => !!deepCheckEmpty(v))) {
      return value
    } else {
      return null
    }
  } else if (value instanceof Map) {
    if (value.size > 0 && Array.from(value.values()).some(v => !!deepCheckEmpty(v))) {
      return value
    } else {
      return null
    }
  } else if (value instanceof Object) {
    if (Object.keys(value).length > 0 && Object.values(value).some(v => !!deepCheckEmpty(v))) {
      return Object.keys(value).length > 0 ? value : null
    } else {
      return null
    }
  } else if (value instanceof String) {
    return value.trim().length > 0 ? value : null
  } else {
    return value ? value : null
  }
}

const getOverlaidConfigs = (
  entry: ConfigChangeHistoryEntry,
): {oldOverlaidConfig: InternalLtiConfiguration; newOverlaidConfig: InternalLtiConfiguration} => {
  return {
    oldOverlaidConfig: entry.old_configuration.overlaid_internal_config,
    newOverlaidConfig: entry.new_configuration.overlaid_internal_config,
  }
}

const diffArrays = <T>(
  oldArray: T[] | null | undefined,
  newArray: T[] | null | undefined,
): ArrayDiff<T> => {
  const oldItems = oldArray || []
  const newItems = newArray || []

  const oldSet = new Set(oldItems)
  const newSet = new Set(newItems)

  const added = newItems.filter(item => !oldSet.has(item))
  const removed = oldItems.filter(item => !newSet.has(item))

  if (added.length === 0 && removed.length === 0) {
    return null
  }

  return deepCheckEmpty({added, removed})
}

const diffStringRecords = (
  oldRecord: Record<string, string> | null | undefined,
  newRecord: Record<string, string> | null | undefined,
): StringRecordDiff => {
  const oldFields = oldRecord || {}
  const newFields = newRecord || {}

  const added: Record<string, string> = {}
  const removed: Record<string, string> = {}

  const allKeys = new Set([...Object.keys(oldFields), ...Object.keys(newFields)])

  for (const key of allKeys) {
    const oldValue = oldFields[key]
    const newValue = newFields[key]

    if (oldValue !== newValue) {
      if (oldValue !== undefined) {
        removed[key] = oldValue
      }
      if (newValue !== undefined) {
        added[key] = newValue
      }
    }
  }

  return deepCheckEmpty({added, removed})
}

const diffLaunchSettings = (
  oldConfig: InternalLtiConfiguration,
  newConfig: InternalLtiConfiguration,
): LaunchSettingsDiff => {
  const redirectUris = diffArrays(oldConfig?.redirect_uris, newConfig?.redirect_uris)
  const targetLinkUri = createDiffValue(oldConfig?.target_link_uri, newConfig?.target_link_uri)
  const oidcInitiationUrl = createDiffValue(
    oldConfig.oidc_initiation_url,
    newConfig.oidc_initiation_url,
  )
  const oidcInitiationUrls = diffStringRecords(
    oldConfig?.oidc_initiation_urls,
    newConfig?.oidc_initiation_urls,
  )
  const publicJwk = createDiffValue(oldConfig?.public_jwk, newConfig?.public_jwk)
  const publicJwkUrl = createDiffValue(oldConfig?.public_jwk_url, newConfig?.public_jwk_url)
  const domain = createDiffValue(oldConfig?.domain, newConfig?.domain)
  const customFields = diffStringRecords(oldConfig?.custom_fields, newConfig?.custom_fields)

  return deepCheckEmpty({
    redirectUris,
    targetLinkUri,
    oidcInitiationUrl,
    oidcInitiationUrls,
    publicJwk,
    publicJwkUrl,
    domain,
    customFields,
  })
}

type PlacementMap = Map<LtiPlacement, InternalPlacementConfiguration>

const buildPlacementMap = (placements: InternalPlacementConfiguration[]): PlacementMap => {
  return new Map(placements.map(placement => [placement.placement, placement]))
}

const placementEnabled = (placementConfig: InternalPlacementConfiguration): boolean => {
  return placementConfig.enabled !== false && placementConfig.enabled !== 'false'
}

const calculateAddedPlacements = (
  oldPlacements: PlacementMap,
  newPlacements: PlacementMap,
): Array<LtiPlacement> => {
  const added: Array<LtiPlacement> = []

  for (const [placement, config] of newPlacements) {
    const oldConfig = oldPlacements.get(placement)
    if (placementEnabled(config) && (!oldConfig || !placementEnabled(oldConfig))) {
      added.push(placement)
    }
  }
  return added
}

const calculateRemovedPlacements = (
  oldPlacements: PlacementMap,
  newPlacements: PlacementMap,
): Array<LtiPlacement> => {
  const removed: Array<LtiPlacement> = []

  for (const [placement, config] of oldPlacements) {
    const newConfig = newPlacements.get(placement)
    if (placementEnabled(config) && (!newConfig || !placementEnabled(newConfig))) {
      removed.push(placement)
    }
  }
  return removed
}

const diffCourseNavDefault = (
  oldPlacements: PlacementMap,
  newPlacements: PlacementMap,
): Diff<InternalBaseLaunchSettings['default']> | null => {
  const oldCourseNav = oldPlacements.get('course_navigation')
  const newCourseNav = newPlacements.get('course_navigation')

  return createDiffValue(oldCourseNav?.default, newCourseNav?.default)
}

const diffPlacements = (
  oldPlacements: PlacementMap,
  newPlacements: PlacementMap,
): NonNullable<PlacementsDiff>['placementChanges'] => {
  const overridesChanged: NonNullable<PlacementsDiff>['placementChanges'] = new Map()

  const allPlacements = new Set([...oldPlacements.keys(), ...newPlacements.keys()])

  for (const placement of allPlacements) {
    const oldConfig = oldPlacements.get(placement)
    const newConfig = newPlacements.get(placement)

    const changes = {
      targetLinkUri: createDiffValue(oldConfig?.target_link_uri, newConfig?.target_link_uri),
      messageType: createDiffValue(oldConfig?.message_type, newConfig?.message_type),
    }
    if (changes.targetLinkUri !== null || changes.messageType !== null) {
      overridesChanged.set(placement, changes)
    }
  }

  return overridesChanged
}

/**
 * Represents a change in values. If null, no change was made.
 */
export type Diff<T> = {
  oldValue: T
  newValue: T
} | null

export type ArrayDiff<T> = {
  added: T[]
  removed: T[]
} | null

export type StringRecordDiff = {
  added: Record<string, string>
  removed: Record<string, string>
} | null

export type LaunchSettingsDiff = {
  redirectUris: ArrayDiff<string>
  targetLinkUri: Diff<InternalLtiConfiguration['target_link_uri']>
  oidcInitiationUrl: Diff<InternalLtiConfiguration['oidc_initiation_url']>
  oidcInitiationUrls: StringRecordDiff
  publicJwk: Diff<InternalLtiConfiguration['public_jwk']>
  publicJwkUrl: Diff<InternalLtiConfiguration['public_jwk_url']>
  domain: Diff<InternalLtiConfiguration['domain']>
  customFields: StringRecordDiff
} | null

export type PermissionsDiff = ArrayDiff<InternalLtiConfiguration['scopes'][number]>

export type PlacementChanges = {
  targetLinkUri: Diff<InternalBaseLaunchSettings['target_link_uri']>
  messageType: Diff<InternalBaseLaunchSettings['message_type']>
}

export type PlacementsDiff = {
  added: Array<InternalPlacementConfiguration['placement']>
  removed: Array<InternalPlacementConfiguration['placement']>
  courseNavigationDefault: Diff<InternalBaseLaunchSettings['default']> | null
  placementChanges: Map<LtiPlacement, PlacementChanges>
} | null

export type NamingDiff = {
  adminNickname: Diff<LtiRegistrationTrackedAttributes['admin_nickname'] | undefined>
  description: Diff<InternalLtiConfiguration['description'] | undefined>
  placementTexts: Map<LtiPlacement, Diff<InternalBaseLaunchSettings['text'] | undefined>>
} | null

export type IconDiff = {
  iconUrl: Diff<InternalBaseLaunchSettings['icon_url']>
  placementIcons: Map<LtiPlacement, Diff<InternalBaseLaunchSettings['icon_url']>>
} | null

export type PrivacyLevelDiff = Diff<InternalLtiConfiguration['privacy_level']>

export type WorkflowStateDiff = Diff<LtiRegistrationTrackedAttributes['workflow_state']>

export type ContextControlDiff = Omit<LtiContextControl, 'available'> & {
  availabilityChange: NonNullable<Diff<LtiContextControlTrackedAttributes['available'] | undefined>>
}

export type DeploymentDiff = Omit<LtiDeployment, 'context_controls'> & {
  controlDiffs: ContextControlDiff[]
}

export type ConfigChangeEntryWithDiff = ConfigChangeHistoryEntry & {
  internalConfig: {
    launchSettings: LaunchSettingsDiff
    permissions: PermissionsDiff
    privacyLevel: PrivacyLevelDiff
    placements: PlacementsDiff
    naming: NamingDiff
    icons: IconDiff
  } | null
  totalAdditions: number
  totalRemovals: number
}

export type AvailabilityChangeEntryWithDiff = AvailabilityChangeHistoryEntry & {
  deploymentDiffs: DeploymentDiff[]
  totalAdditions: number
  totalRemovals: number
}

export type LtiHistoryEntryWithDiff = ConfigChangeEntryWithDiff | AvailabilityChangeEntryWithDiff

const diffNamingChanges = (
  entry: ConfigChangeHistoryEntry,
  oldPlacements: PlacementMap,
  newPlacements: PlacementMap,
): NamingDiff => {
  const {oldOverlaidConfig, newOverlaidConfig} = getOverlaidConfigs(entry)
  const oldReg = entry.old_configuration.registration
  const newReg = entry.new_configuration.registration

  const allPlacementNames = new Set([...oldPlacements.keys(), ...newPlacements.keys()])

  const placementTexts: NonNullable<NamingDiff>['placementTexts'] = new Map()

  for (const placementName of allPlacementNames) {
    const oldPlacement = oldPlacements.get(placementName)
    const newPlacement = newPlacements.get(placementName)
    const textDiff = createDiffValue(oldPlacement?.text, newPlacement?.text)
    if (textDiff) {
      placementTexts.set(placementName, textDiff)
    }
  }

  return {
    adminNickname: createDiffValue(oldReg?.admin_nickname, newReg?.admin_nickname),
    description: createDiffValue(oldOverlaidConfig?.description, newOverlaidConfig?.description),
    placementTexts,
  }
}

const diffIconChanges = (
  entry: ConfigChangeHistoryEntry,
  oldPlacements: PlacementMap,
  newPlacements: PlacementMap,
): IconDiff => {
  const {oldOverlaidConfig: oldConfig, newOverlaidConfig: newConfig} = getOverlaidConfigs(entry)

  const iconUrl = createDiffValue(
    oldConfig?.launch_settings?.icon_url,
    newConfig?.launch_settings?.icon_url,
  )

  const placementIcons: NonNullable<IconDiff>['placementIcons'] = new Map()

  const allPlacementNames = new Set([...oldPlacements.keys(), ...newPlacements.keys()])

  for (const placementName of allPlacementNames) {
    const oldPlacement = oldPlacements.get(placementName)
    const newPlacement = newPlacements.get(placementName)
    const iconDiff = createDiffValue(oldPlacement?.icon_url, newPlacement?.icon_url)
    if (iconDiff) {
      placementIcons.set(placementName, iconDiff)
    }
  }

  return {
    iconUrl,
    placementIcons,
  }
}

const sumChanges = (
  changes: {additions: number; removals: number}[],
): {additions: number; removals: number} => {
  return changes.reduce(
    (acc, val) => {
      return {
        additions: acc.additions + val.additions,
        removals: acc.removals + val.removals,
      }
    },
    {
      additions: 0,
      removals: 0,
    },
  )
}

const countChanges = (
  diff: ConfigChangeEntryWithDiff['internalConfig'],
): {additions: number; removals: number} => {
  if (diff === null) {
    return {
      additions: 0,
      removals: 0,
    }
  }

  let {additions, removals} = sumChanges([
    countDiff(diff.launchSettings?.targetLinkUri),
    countDiff(diff.launchSettings?.oidcInitiationUrl),
    countDiff(diff.launchSettings?.publicJwk),
    countDiff(diff.launchSettings?.publicJwkUrl),
    countDiff(diff.launchSettings?.domain),
    countDiff(diff.privacyLevel),
    countDiff(diff.placements?.courseNavigationDefault),
    ...Array.from(diff.placements?.placementChanges.values() ?? [])
      .map(v => [countDiff(v.targetLinkUri), countDiff(v.messageType)])
      .flat(),
    countDiff(diff.naming?.adminNickname),
    countDiff(diff.naming?.description),
    ...Array.from(diff.naming?.placementTexts.values() ?? []).map(countDiff),
    countDiff(diff.icons?.iconUrl),
    ...Array.from(diff.icons?.placementIcons.values() ?? []).map(countDiff),
  ])
  additions += diff.launchSettings?.redirectUris?.added.length ?? 0
  removals += diff.launchSettings?.redirectUris?.removed.length ?? 0
  additions += Object.keys(diff.launchSettings?.oidcInitiationUrls?.added ?? {}).length
  removals += Object.keys(diff.launchSettings?.oidcInitiationUrls?.removed ?? {}).length
  additions += Object.keys(diff.launchSettings?.customFields?.added ?? {}).length
  removals += Object.keys(diff.launchSettings?.customFields?.removed ?? {}).length
  additions += diff.permissions?.added?.length ?? 0
  removals += diff.permissions?.removed?.length ?? 0
  additions += diff.placements?.added?.length ?? 0
  removals += diff.placements?.removed.length ?? 0

  return {additions, removals}
}

/**
 * Exported for testing
 * @private
 */
export const createDiffValue = <T>(oldValue: T, newValue: T): Diff<T> => {
  if (isEqual(oldValue, newValue)) {
    return null
  }
  return {oldValue, newValue}
}

/**
 * Exported for testing
 * @private
 */
export const countDiff = <T>(
  diffValue: Diff<T> | null | undefined,
): {additions: number; removals: number} => {
  if (!diffValue) {
    return {additions: 0, removals: 0}
  }
  // We use the idea of being nullish to count changes, not being falsy.
  return {
    additions: diffValue.newValue !== undefined && diffValue.newValue !== null ? 1 : 0,
    removals: diffValue.oldValue !== undefined && diffValue.oldValue !== null ? 1 : 0,
  }
}

/**
 * Exported for testing
 * @private
 */
export const diffConfigChangeEntry = (
  entry: ConfigChangeHistoryEntry,
): ConfigChangeEntryWithDiff => {
  const {oldOverlaidConfig, newOverlaidConfig} = getOverlaidConfigs(entry)
  const oldPlacements = buildPlacementMap(oldOverlaidConfig.placements)
  const newPlacements = buildPlacementMap(newOverlaidConfig.placements)

  const placementsAdded = calculateAddedPlacements(oldPlacements, newPlacements)
  const placementsRemoved = calculateRemovedPlacements(oldPlacements, newPlacements)
  const courseNavigationDefault = diffCourseNavDefault(oldPlacements, newPlacements)
  const overridesChanged = diffPlacements(oldPlacements, newPlacements)

  const internalConfig = deepCheckEmpty({
    launchSettings: diffLaunchSettings(oldOverlaidConfig, newOverlaidConfig),
    permissions: diffArrays(oldOverlaidConfig.scopes, newOverlaidConfig.scopes),
    privacyLevel: createDiffValue(oldOverlaidConfig.privacy_level, newOverlaidConfig.privacy_level),
    placements: deepCheckEmpty({
      added: placementsAdded,
      removed: placementsRemoved,
      courseNavigationDefault,
      placementChanges: overridesChanged,
    }),
    naming: deepCheckEmpty(diffNamingChanges(entry, oldPlacements, newPlacements)),
    icons: deepCheckEmpty(diffIconChanges(entry, oldPlacements, newPlacements)),
  })
  const {additions, removals} = countChanges(internalConfig)

  return {
    ...entry,
    internalConfig,
    totalAdditions: additions,
    totalRemovals: removals,
  }
}

/**
 * Diffs context controls between old and new deployments, grouping by deployment.
 *
 * Processes each deployment independently, comparing its old and new controls.
 * Only includes deployments where at least one control's availability changed.
 *
 * Changes detected:
 * - Additions: control exists in new but not old
 * - Deletions: control exists in old but not new
 * - Modifications: control exists in both but availability differs, or control
 * was restored from deletion
 *
 * @param entry - The availability change history entry
 * @returns Entry augmented with deployment diffs
 */
const diffAvailabilityChangeEntry = (
  entry: AvailabilityChangeHistoryEntry,
): AvailabilityChangeEntryWithDiff => {
  const oldDeploymentsByIdMap = new Map(
    entry.old_controls_by_deployment.map(d => [d.deployment_id, d]),
  )
  const newDeploymentsByIdMap = new Map(
    entry.new_controls_by_deployment.map(d => [d.deployment_id, d]),
  )

  const allDeploymentIds = new Set([
    ...oldDeploymentsByIdMap.keys(),
    ...newDeploymentsByIdMap.keys(),
  ])

  const deploymentDiffs: DeploymentDiff[] = []
  let totalAdditions = 0
  let totalRemovals = 0

  for (const deploymentId of allDeploymentIds) {
    const oldDeployment = oldDeploymentsByIdMap.get(deploymentId)
    const newDeployment = newDeploymentsByIdMap.get(deploymentId)

    const oldControlsById = new Map((oldDeployment?.context_controls ?? []).map(c => [c.id, c]))
    const newControlsById = new Map((newDeployment?.context_controls ?? []).map(c => [c.id, c]))

    const allControlIds = new Set([...oldControlsById.keys(), ...newControlsById.keys()])

    const controlDiffs: ContextControlDiff[] = []

    for (const controlId of allControlIds) {
      const oldControl = oldControlsById.get(controlId)
      const newControl = newControlsById.get(controlId)

      // Account for deletion followed by restoration.
      const oldAvailable =
        oldControl?.workflow_state === 'deleted' ? undefined : oldControl?.available
      const newAvailable =
        newControl?.workflow_state === 'deleted' ? undefined : newControl?.available

      const diff = createDiffValue(oldAvailable, newAvailable)

      if (diff === null) continue

      const control = newControl ?? oldControl!

      controlDiffs.push({
        ...control,
        availabilityChange: diff,
      })
    }

    // Only include deployments with actual changes
    if (controlDiffs.length > 0) {
      const deployment = newDeployment ?? oldDeployment!

      deploymentDiffs.push({
        ...deployment,
        controlDiffs,
      })

      const {additions, removals} = countContextControlChanges(controlDiffs)
      totalAdditions += additions
      totalRemovals += removals
    }
  }

  return {
    ...entry,
    deploymentDiffs,
    totalAdditions,
    totalRemovals,
  }
}

const countContextControlChanges = (
  controlDiffs: ContextControlDiff[],
): {additions: number; removals: number} =>
  sumChanges(controlDiffs.map(c => countDiff(c.availabilityChange)))

/**
 * Parses an LtiRegistrationHistoryEntry into a structured diff object organized by UI concerns.
 *
 * Compares old and new configuration attributes to produce a diff containing:
 * - Launch settings (redirect URIs, OIDC URLs, JWK, domain, custom fields)
 * - Permissions (added/removed scopes)
 * - Privacy level changes
 * - Placement changes (added, removed, overrides, course navigation default)
 * - Naming changes (title, name, admin nickname, description, placement texts)
 * - Icon changes (global and per-placement)
 *
 * Note that for many fields, modifying is treated as both addition and removal to simplify rendering.
 *
 * @param entry - The history entry containing old and new attribute snapshots
 * @returns A structured diff object suitable for rendering in confirmation UI screens
 */
export const diffHistoryEntry = (entry: LtiRegistrationHistoryEntry): LtiHistoryEntryWithDiff => {
  if (isEntryForConfigChange(entry)) {
    return diffConfigChangeEntry(entry)
  } else {
    return diffAvailabilityChangeEntry(entry)
  }
}

export const diffHistoryEntries = (
  entries: LtiRegistrationHistoryEntry[],
): LtiHistoryEntryWithDiff[] => {
  return entries.map(diffHistoryEntry)
}
