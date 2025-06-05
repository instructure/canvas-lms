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

export type OutcomeIconType =
  | 'unassessed'
  | 'exceeds_mastery'
  | 'mastery'
  | 'near_mastery'
  | 'remediation'
  | 'no_evidence'

/**
 * Generates a URL to the appropriate SVG icon based on points and mastery level
 * @param points - The points earned for this outcome, or null if unassessed
 * @param masteryAt - The points threshold for mastery
 * @returns The URL path to the corresponding outcome icon
 */
export const svgUrl = (points: number | null, masteryAt: number): string => {
  return `/images/outcomes/${getTagIcon(points, masteryAt)}.svg`
}

/*
 *  NOTE: This is only for Account Level Mastery Scales FF Enabled
 *  This code block only works with the default scale for outcomes
 *  After OUT-5226 (https://instructure.atlassian.net/browse/OUT-5226), support
 *  for custom outcome scales will be included
 */
const getTagIcon = (points: number | null, masteryAt: number): OutcomeIconType => {
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
