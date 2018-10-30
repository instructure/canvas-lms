/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

export function buildEvent(attr = {}, payload = {}) {
  return {
    assignmentId: '2301',
    canvadocId: null,
    eventType: 'unknown',
    id: '4901',
    submissionId: null,
    userId: '1101',
    ...attr,
    createdAt: attr.createdAt ? new Date(attr.createdAt) : new Date(),
    payload
  }
}

export function buildAssignmentCreatedEvent(attr = {}, payload = {}) {
  const fullPayload = {
    anonymous_grading: true,
    anonymous_instructor_annotations: true,
    final_grader_id: '1102',
    grader_comments_visible_to_graders: true,
    grader_count: 2,
    grader_names_visible_to_final_grader: true,
    graders_anonymous_to_graders: false,
    moderated_grading: true,
    muted: true,
    omit_from_final_grade: false,
    points_possible: 10,
    ...payload
  }

  return buildEvent({...attr, eventType: 'assignment_created'}, fullPayload)
}

export function buildAssignmentUpdatedEvent(attr = {}, payload = {}) {
  return buildEvent({...attr, eventType: 'assignment_updated'}, payload)
}
