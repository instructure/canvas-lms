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

import type {OutcomeIconType} from './icons'

export interface ProficiencyRating {
  points: number
  color: string
  description?: string
  mastery?: boolean
}

export type MasteryLevelResult = OutcomeIconType | number

/**
 * Finds the index of the mastery level in the ratings array
 * @param ratings - Array of proficiency ratings sorted by points descending
 * @returns The index where mastery is set, or -1 if not found
 */
const findMasteryIndex = (ratings: ProficiencyRating[]): number => {
  return ratings.findIndex(rating => rating.mastery === true)
}

/**
 * Finds which rating level a score belongs to
 * @param points - The score to evaluate
 * @param ratings - Array of proficiency ratings sorted by points descending
 * @returns The index of the rating level (0-based)
 */
const findRatingIndex = (points: number, ratings: ProficiencyRating[]): number => {
  // Ratings are sorted descending (highest to lowest)
  // A score belongs to a rating level if it's >= that rating's points
  // We find the highest rating level (smallest index) where the score qualifies

  for (let i = 0; i < ratings.length; i++) {
    if (points >= ratings[i].points) {
      return i
    }
  }

  // If score is below all rating thresholds, it belongs to the lowest level
  return ratings.length - 1
}

/**
 * Determines if numbers should be used instead of icons based on the rules
 * @param levelCount - Number of proficiency levels
 * @param masteryIndex - Index where mastery is set (0-based, from highest to lowest)
 * @returns true if numbers should be used, false if icons should be used
 */
export const shouldUseNumbers = (levelCount: number, masteryIndex: number): boolean => {
  // More than 5 levels always use numbers
  if (levelCount > 5) {
    return true
  }

  // No mastery set - use numbers as fallback
  if (masteryIndex === -1) {
    return true
  }

  switch (levelCount) {
    case 1:
      // 1 level: always use icons (mastery can only be at level 0)
      return false
    case 2:
      // 2 levels: always use icons regardless of mastery position
      return false
    case 3:
      // 3 levels: use numbers only if mastery at level 2 (0-indexed, which is the lowest)
      return masteryIndex === 2
    case 4:
      // 4 levels: use numbers if mastery at levels 0 (highest), 2, or 3 (lowest)
      // Only use icons if mastery is at level 1 (0-indexed, which is level 3 in 1-indexed)
      return masteryIndex !== 1
    case 5:
      // 5 levels: use numbers if mastery at levels 0 (highest), 2, 3, or 4 (lowest)
      // Only use icons if mastery is at level 1 (0-indexed, which is level 4 in 1-indexed)
      return masteryIndex !== 1
    default:
      return false
  }
}

/**
 * Maps a score to an icon type based on level count and position
 * @param levelCount - Number of proficiency levels
 * @param scoreIndex - Index where the score falls (0-based, from highest)
 * @param masteryIndex - Index where mastery is set (0-based, from highest)
 * @returns The icon type to use
 */
const mapToIconType = (
  levelCount: number,
  scoreIndex: number,
  masteryIndex: number,
): OutcomeIconType => {
  // Handle 1 level case
  if (levelCount === 1) {
    return 'mastery'
  }

  // Handle 2 level case
  if (levelCount === 2) {
    if (masteryIndex === 0) {
      // Mastery at highest level
      return scoreIndex === 0 ? 'mastery' : 'near_mastery'
    } else {
      // Mastery at lowest level
      return scoreIndex === 0 ? 'exceeds_mastery' : 'mastery'
    }
  }

  // Handle 3 level case
  if (levelCount === 3) {
    if (masteryIndex === 0) {
      // Mastery at level 3 (highest)
      const iconMap: OutcomeIconType[] = ['mastery', 'near_mastery', 'remediation']
      return iconMap[scoreIndex] || 'no_evidence'
    } else if (masteryIndex === 1) {
      // Mastery at level 2 (middle)
      const iconMap: OutcomeIconType[] = ['exceeds_mastery', 'mastery', 'near_mastery']
      return iconMap[scoreIndex] || 'no_evidence'
    }
  }

  // Handle 4 level case
  if (levelCount === 4) {
    // Standard mapping: 4=exceeds, 3=mastery, 2=near, 1=remediation
    const iconMap: OutcomeIconType[] = ['exceeds_mastery', 'mastery', 'near_mastery', 'remediation']
    return iconMap[scoreIndex] || 'no_evidence'
  }

  // Handle 5 level case
  if (levelCount === 5) {
    // Standard mapping: 5=exceeds, 4=mastery, 3=near, 2=remediation, 1=no_evidence
    const iconMap: OutcomeIconType[] = [
      'exceeds_mastery',
      'mastery',
      'near_mastery',
      'remediation',
      'no_evidence',
    ]
    return iconMap[scoreIndex] || 'no_evidence'
  }

  // Default fallback
  return 'no_evidence'
}

/**
 * Determines the mastery level (icon or number) based on score and proficiency ratings
 * @param points - The score to evaluate (null if unassessed)
 * @param proficiencyRatings - Array of proficiency ratings
 * @returns Either an icon type or a numeric level (1-indexed)
 */
export const determineMasteryLevel = (
  points: number | null | undefined,
  proficiencyRatings: ProficiencyRating[],
): MasteryLevelResult => {
  // Handle unassessed case
  if (points == null) {
    return 'unassessed'
  }

  // Validate ratings
  if (!proficiencyRatings || proficiencyRatings.length === 0) {
    return 'unassessed'
  }

  // Sort ratings by points descending (highest to lowest)
  const sortedRatings = [...proficiencyRatings].sort((a, b) => b.points - a.points)

  // Find mastery index
  const masteryIndex = findMasteryIndex(sortedRatings)

  // Find score's rating index
  const scoreIndex = findRatingIndex(points, sortedRatings)

  // Check if should use numbers
  if (shouldUseNumbers(sortedRatings.length, masteryIndex)) {
    // Return 1-indexed level number
    return scoreIndex + 1
  }

  // Map to icon type
  return mapToIconType(sortedRatings.length, scoreIndex, masteryIndex)
}

/**
 * Gets the color for a rating level
 * @param levelNumber - The level number (1-indexed)
 * @param proficiencyRatings - Array of proficiency ratings
 * @returns The color hex code, or undefined if not found
 */
export const getColorForLevel = (
  levelNumber: number,
  proficiencyRatings: ProficiencyRating[],
): string | undefined => {
  const sortedRatings = [...proficiencyRatings].sort((a, b) => b.points - a.points)
  return sortedRatings[levelNumber - 1]?.color
}

/**
 * Gets the description for a rating level
 * @param levelNumber - The level number (1-indexed)
 * @param proficiencyRatings - Array of proficiency ratings
 * @returns The description, or undefined if not found
 */
export const getDescriptionForLevel = (
  levelNumber: number,
  proficiencyRatings: ProficiencyRating[],
): string | undefined => {
  const sortedRatings = [...proficiencyRatings].sort((a, b) => b.points - a.points)
  return sortedRatings[levelNumber - 1]?.description
}
