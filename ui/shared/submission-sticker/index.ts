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

import Sticker from './react/components/Sticker'

type Features = {
  stickersEnabled: boolean
  assignmentEnhancementsEnabled: boolean
}

type Assignment = {
  anonymizeStudents: boolean
  moderatedGrading: boolean
  gradesPublished: boolean
  submissionTypes: string[]
}

export function stickersAvailable(features: Features, assignment: Assignment): boolean {
  const unsupportedTypes = ['online_quiz', 'discussion_topic', 'wiki_page']

  if (!features.stickersEnabled) return false
  if (!features.assignmentEnhancementsEnabled) return false
  if (assignment.submissionTypes.some(subType => unsupportedTypes.includes(subType))) return false
  if (assignment.anonymizeStudents) return false
  if (assignment.moderatedGrading && !assignment.gradesPublished) return false

  return true
}

export default Sticker
