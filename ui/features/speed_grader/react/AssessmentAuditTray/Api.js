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

import axios from '@canvas/axios'
import * as timezone from '@canvas/datetime'

export default class Api {
  loadAssessmentAuditTrail(courseId, assignmentId, submissionId) {
    const url = `/courses/${courseId}/assignments/${assignmentId}/submissions/${submissionId}/audit_events`
    return axios.get(url).then(response => {
      const auditEvents = response.data.audit_events.map(auditEvent => ({
        assignmentId: auditEvent.assignment_id,
        canvadocId: auditEvent.canvadoc_id,
        createdAt: timezone.parse(auditEvent.created_at),
        eventType: auditEvent.event_type,
        externalToolId: auditEvent.context_external_tool_id,
        id: auditEvent.id,
        payload: auditEvent.payload,
        quizId: auditEvent.quiz_id,
        submissionId: auditEvent.submission_id,
        userId: auditEvent.user_id,
      }))

      const users = response.data.users.map(user => ({
        id: user.id,
        name: user.name,
        role: user.role,
      }))

      const externalTools = response.data.tools.map(tool => ({
        id: tool.id,
        name: tool.name,
        role: tool.role,
      }))

      const quizzes = response.data.quizzes.map(quiz => ({
        id: quiz.id,
        name: quiz.name,
        role: quiz.role,
      }))

      return {auditEvents, users, externalTools, quizzes}
    })
  }
}
