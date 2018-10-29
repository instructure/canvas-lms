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

import IconAdd from '@instructure/ui-icons/lib/Line/IconAdd'
import IconEdit from '@instructure/ui-icons/lib/Line/IconEdit'
import IconGradebook from '@instructure/ui-icons/lib/Line/IconGradebook'
import IconMuted from '@instructure/ui-icons/lib/Line/IconMuted'
import IconQuestion from '@instructure/ui-icons/lib/Line/IconQuestion'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import IconUnmuted from '@instructure/ui-icons/lib/Line/IconUnmuted'
import I18n from 'i18n!speed_grader'

const defaultIcon = IconQuestion
const iconsByEventTrailType = {
  created: IconAdd,
  deleted: IconTrash,
  gradebook: IconGradebook,
  muted: IconMuted,
  unmuted: IconUnmuted,
  updated: IconEdit
}

const defaultLabel = I18n.t('Unknown event')
const labelByEventType = {
  assignment_created: I18n.t('Assignment created'),
  assignment_updated: I18n.t('Assignment updated'),
  docviewer_area_created: I18n.t('Docviewer area created'),
  docviewer_area_deleted: I18n.t('Docviewer area deleted'),
  docviewer_area_updated: I18n.t('Docviewer area updated'),
  docviewer_comment_created: I18n.t('Docviewer comment created'),
  docviewer_comment_deleted: I18n.t('Docviewer comment deleted'),
  docviewer_comment_updated: I18n.t('Docviewer comment updated'),
  docviewer_free_draw_created: I18n.t('Docviewer free draw created'),
  docviewer_free_draw_deleted: I18n.t('Docviewer free draw deleted'),
  docviewer_free_draw_updated: I18n.t('Docviewer free draw updated'),
  docviewer_free_text_created: I18n.t('Docviewer free text created'),
  docviewer_free_text_deleted: I18n.t('Docviewer free text deleted'),
  docviewer_free_text_updated: I18n.t('Docviewer free text updated'),
  docviewer_highlight_created: I18n.t('Docviewer highlight created'),
  docviewer_highlight_deleted: I18n.t('Docviewer highlight deleted'),
  docviewer_highlight_updated: I18n.t('Docviewer highlight updated'),
  docviewer_point_created: I18n.t('Docviewer point created'),
  docviewer_point_deleted: I18n.t('Docviewer point deleted'),
  docviewer_point_updated: I18n.t('Docviewer point updated'),
  docviewer_strikeout_created: I18n.t('Docviewer strikeout created'),
  docviewer_strikeout_deleted: I18n.t('Docviewer strikeout deleted'),
  docviewer_strikeout_updated: I18n.t('Docviewer strikeout updated'),
  grades_posted: I18n.t('Grades posted'),
  provisional_grade_created: I18n.t('Provisional grade created'),
  provisional_grade_selected: I18n.t('Provisional grade selected'),
  provisional_grade_updated: I18n.t('Provisional grade updated'),
  provisional_grade_deleted: I18n.t('Provisional grade deleted'),
  rubric_created: I18n.t('Rubric created'),
  rubric_deleted: I18n.t('Rubric deleted'),
  rubric_updated: I18n.t('Rubric updated'),
  submission_comment_created: I18n.t('Submission comment created'),
  submission_comment_deleted: I18n.t('Submission comment deleted'),
  submission_comment_updated: I18n.t('Submission comment updated'),
  submission_updated: I18n.t('Submission updated')
}

const defaultTrailType = 'unknown'
const trailTypeByEventType = {
  assignment_created: 'created',
  assignment_updated: 'updated',
  docviewer_area_created: 'created',
  docviewer_area_deleted: 'deleted',
  docviewer_area_updated: 'updated',
  docviewer_comment_created: 'created',
  docviewer_comment_deleted: 'deleted',
  docviewer_comment_updated: 'updated',
  docviewer_free_draw_created: 'created',
  docviewer_free_draw_deleted: 'deleted',
  docviewer_free_draw_updated: 'updated',
  docviewer_free_text_created: 'created',
  docviewer_free_text_deleted: 'deleted',
  docviewer_free_text_updated: 'updated',
  docviewer_highlight_created: 'created',
  docviewer_highlight_deleted: 'deleted',
  docviewer_highlight_updated: 'updated',
  docviewer_point_created: 'created',
  docviewer_point_deleted: 'deleted',
  docviewer_point_updated: 'updated',
  docviewer_strikeout_created: 'created',
  docviewer_strikeout_deleted: 'deleted',
  docviewer_strikeout_updated: 'updated',
  grades_posted: 'gradebook',
  provisional_grade_created: 'created',
  provisional_grade_selected: 'updated',
  provisional_grade_updated: 'updated',
  provisional_grade_deleted: 'deleted',
  rubric_created: 'created',
  rubric_deleted: 'deleted',
  rubric_updated: 'updated',
  submission_comment_created: 'created',
  submission_comment_deleted: 'deleted',
  submission_comment_updated: 'updated',
  submission_updated: 'updated'
}

function trailTypeFor(auditEvent) {
  return trailTypeByEventType[auditEvent.eventType] || defaultTrailType
}

export function iconFor(auditEvent) {
  return iconsByEventTrailType[trailTypeFor(auditEvent)] || defaultIcon
}

export function labelFor(auditEvent) {
  return labelByEventType[auditEvent.eventType] || defaultLabel
}

export function snippetFor({eventType, payload}) {
  if (eventType === 'submission_comment_created' || eventType === 'submission_comment_updated') {
    return payload.comment
  }

  if (eventType === 'docviewer_comment_created' || eventType === 'docviewer_comment_updated') {
    return payload.annotation_body.content
  }

  return null
}
