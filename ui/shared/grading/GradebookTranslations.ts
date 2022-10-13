/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebooktranslations')

const GRADEBOOK_TRANSLATIONS = {
  submission_tooltip_unpublished_assignment: I18n.t('This assignment is unpublished'),
  submission_tooltip_dropped: I18n.t('Dropped for grading purposes'),
  submission_tooltip_excused: I18n.t('Assignment Excused'),
  submission_tooltip_late: I18n.t('Submitted Late'),
  submission_tooltip_missing: I18n.t('Missing Submission'),
  submission_tooltip_anonymous: I18n.t('Anonymous'),
  submission_tooltip_moderated: I18n.t('Moderated Assignment'),
  submission_tooltip_muted: I18n.t('Assignment Muted'),
  submission_tooltip_resubmitted: I18n.t('Resubmitted since last graded'),
  submission_tooltip_ungraded: I18n.t('Not factored into grading'),
  submission_tooltip_online_url: I18n.t('URL Submission'),
  submission_tooltip_discussion_topic: I18n.t('Discussion Submission'),
  submission_tooltip_online_upload: I18n.t('File Upload Submission'),
  submission_tooltip_online_text_entry: I18n.t('Text Entry Submission'),
  submission_tooltip_pending_review: I18n.t('This quiz needs review'),
  submission_tooltip_media_comment: I18n.t('Media Comment Submission'),
  submission_tooltip_media_recording: I18n.t('Media Recording Submission'),
  submission_tooltip_online_quiz: I18n.t('Quiz Submission'),
  submission_tooltip_turnitin: I18n.t('Has similarity score'),
  submission_tooltip_not_in_any_grading_period: I18n.t(
    'This submission is not in any grading period'
  ),
  submission_tooltip_in_another_grading_period: I18n.t(
    'This submission is in another grading period'
  ),
  submission_tooltip_in_closed_grading_period: I18n.t(
    'This submission is in a closed grading period'
  ),
  submission_update_error: I18n.t(
    'There was an error updating this assignment. Please refresh the page and try again.'
  ),
  submission_too_many_points_warning: I18n.t(
    'This student was just awarded an unusually high grade.'
  ),
  submission_negative_points_warning: I18n.t('This student was just awarded negative points.'),
  submission_pass: I18n.t('pass'),
  submission_fail: I18n.t('fail'),
  submission_blank: I18n.t('blank'),
  submission_excused: I18n.t('excused'),
}

export default GRADEBOOK_TRANSLATIONS
