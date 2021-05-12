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

export const isGraded = (assignment = null) => {
  return assignment !== null && (assignment?.dueAt || assignment?.pointsPossible)
}

export const getSpeedGraderUrl = (courseId, assignmentId, authorId = null) => {
  let speedGraderUrl = `/courses/${courseId}/gradebook/speed_grader?assignment_id=${assignmentId}`

  if (authorId !== null) {
    speedGraderUrl += `&student_id=${authorId}`
  }

  return speedGraderUrl
}

export const getEditUrl = (courseId, discussionTopicId) => {
  return `/courses/${courseId}/discussion_topics/${discussionTopicId}/edit`
}
