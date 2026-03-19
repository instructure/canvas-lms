/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {
  determineMasteryLevel,
  type ProficiencyRating,
  type MasteryLevelResult,
} from './masteryScaleLogic'

export type OutcomeIconType =
  | 'unassessed'
  | 'exceeds_mastery'
  | 'mastery'
  | 'near_mastery'
  | 'remediation'
  | 'no_evidence'

// Re-export types for convenience
export type {ProficiencyRating, MasteryLevelResult}

/**
 * Generates a URL to the appropriate SVG icon based on points and mastery level
 * @param points - The points earned for this outcome, or null if unassessed
 * @param masteryAt - The points threshold for mastery
 * @param proficiencyRatings - Optional array of proficiency ratings for custom scales
 * @returns The URL path to the corresponding outcome icon (or null if numeric level)
 */
export const svgUrl = (
  points: number | null | undefined,
  masteryAt: number,
  proficiencyRatings?: ProficiencyRating[],
): string | null => {
  const result = getTagIcon(points, masteryAt, proficiencyRatings)
  // If result is a number, we can't return an SVG URL
  if (typeof result === 'number') {
    return null
  }
  return `/images/outcomes/${result}.svg`
}

/**
 * Determines the mastery level icon or numeric level based on score and proficiency ratings
 *
 * @param points - The points earned for this outcome, or null if unassessed
 * @param masteryAt - The points threshold for mastery (used for backward compatibility)
 * @param proficiencyRatings - Optional array of proficiency ratings for custom scales
 * @returns Either an OutcomeIconType or a numeric level (1-indexed)
 *
 * When proficiencyRatings is provided, uses the new algorithm that supports:
 * - Non-equal point spacing (e.g., 0, 3, 5, 7, 9)
 * - Variable level counts (1-5+ levels)
 * - Mastery at different positions
 * - Automatic switching between icons and numbers based on configuration
 *
 * When proficiencyRatings is not provided, falls back to legacy logic that assumes
 * a 5-level scale with equal spacing.
 */
export const getTagIcon = (
  points: number | null | undefined,
  masteryAt: number,
  proficiencyRatings?: ProficiencyRating[],
): MasteryLevelResult => {
  // If proficiencyRatings provided, use new logic
  if (proficiencyRatings && proficiencyRatings.length > 0) {
    return determineMasteryLevel(points, proficiencyRatings)
  }

  // Otherwise fall back to old logic for backward compatibility
  // NOTE: This legacy code only works with the default 5-level scale for outcomes
  if (points == null) {
    return 'unassessed'
  }
  const score = points - masteryAt
  switch (true) {
    case score > 0:
      return 'exceeds_mastery'
    case score === 0:
      return 'mastery'
    case score === -1:
      return 'near_mastery'
    case score === -2:
      return 'remediation'
    default:
      return 'no_evidence'
  }
}
