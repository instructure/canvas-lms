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

/**
 * Feature flag requirements for specific LTI placements.
 * Map placement names to their required feature flag in window.ENV.FEATURES.
 * Add new placements and their feature flags here as needed.
 */
const PlacementFeatureFlagRequirements: Record<string, string> = {
  top_navigation: 'top_navigation_placement',
  ActivityAssetProcessor: 'lti_asset_processor',
  ActivityAssetProcessorContribution: 'lti_asset_processor_discussions',
} as const

/**
 * Check if a placement is enabled based on feature flags.
 * Returns true if the placement has no feature flag requirement or if its feature flag is enabled.
 *
 * @param placement The placement to check
 * @returns true if the placement should be visible, false otherwise
 */
export const isPlacementEnabledByFeatureFlag = (placement: string): boolean => {
  const featureFlagKey = PlacementFeatureFlagRequirements[placement]
  if (!featureFlagKey) {
    return true // No feature flag requirement, placement is always enabled
  }
  return (window.ENV.FEATURES as Record<string, boolean | undefined>)?.[featureFlagKey] ?? false
}

/**
 * Filter an array of placements based on feature flags.
 * Removes placements that are behind disabled feature flags.
 *
 * @param placements Array of placement names to filter
 * @returns Filtered array containing only enabled placements
 */
export const filterPlacementsByFeatureFlags = <T extends string>(
  placements: readonly T[] | T[],
): T[] => {
  return placements.filter(isPlacementEnabledByFeatureFlag) as T[]
}

/**
 * Filter an array of placement objects based on feature flags.
 * Removes placement objects whose placement property is behind a disabled feature flag.
 *
 * @param placements Array of objects with a 'placement' property
 * @returns Filtered array containing only objects with enabled placements
 */
export const filterPlacementObjectsByFeatureFlags = <T extends {placement: string}>(
  placements: T[],
): T[] => {
  return placements.filter(p => isPlacementEnabledByFeatureFlag(p.placement))
}
