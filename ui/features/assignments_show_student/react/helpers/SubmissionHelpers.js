/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18n!assignments_2_submission_helpers'

export function getCurrentSubmissionType(submission) {
  if (submission.url !== null) {
    return 'online_url'
  } else if (submission.body !== null && submission.body !== '') {
    return 'online_text_entry'
  } else if (submission.attachments.length !== 0) {
    return 'online_upload'
  }
}

export function friendlyTypeName(type) {
  switch (type) {
    case 'media_recording':
      return I18n.t('Media')
    case 'online_text_entry':
      return I18n.t('Text')
    case 'online_upload':
      return I18n.t('Upload')
    case 'online_url':
      return I18n.t('Web URL')
    default:
      throw new Error('submission type not yet supported in A2')
  }
}

export function multipleTypesDrafted(submission) {
  const submissionDraft = submission?.submissionDraft
  const matchingCriteria = [
    submissionDraft?.meetsTextEntryCriteria,
    submissionDraft?.meetsUploadCriteria,
    submissionDraft?.meetsUrlCriteria
  ].filter(criteria => criteria === true)

  return matchingCriteria.length > 1
}
