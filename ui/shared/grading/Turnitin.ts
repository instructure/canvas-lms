// @ts-nocheck
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
import {max, invert} from 'lodash'
import {originalityReportSubmissionKey} from './originalityReportHelper'
import type {SubmissionOriginalityData, SubmissionWithOriginalityReport} from './grading.d'

const I18n = useI18nScope('turnitin')

export const extractDataTurnitin = function (submission: SubmissionWithOriginalityReport) {
  let attachment, i, item, len, plagData, ref, turnitin
  plagData = submission != null ? submission.turnitin_data : undefined
  if (plagData == null) {
    plagData = submission?.vericite_data
  }
  if (plagData == null) {
    return
  }
  const data: {
    items: Array<{id: string; data: SubmissionOriginalityData}>
    state: string
  } = {
    items: [],
    state: 'none',
  }
  if (submission.attachments && submission.submission_type === 'online_upload') {
    ref = submission.attachments
    for (i = 0, len = ref.length; i < len; i++) {
      attachment = ref[i]
      attachment = attachment.attachment || attachment
      turnitin = plagData?.['attachment_' + attachment.id]
      if (turnitin) {
        data.items.push(turnitin)
      }
    }
  } else if (submission.submission_type === 'online_text_entry') {
    if (
      (turnitin =
        plagData?.[originalityReportSubmissionKey(submission)] ||
        plagData?.['submission_' + submission.id])
    ) {
      data.items.push(turnitin)
    }
  }
  if (!data.items.length) {
    return
  }
  const stateList = [
    'no',
    'none',
    'acceptable',
    'warning',
    'problem',
    'failure',
    'pending',
    'error',
  ]
  const stateMap = invert(stateList)
  const states = (function () {
    let j, len1
    const ref2 = data.items
    const results: number[] = []
    for (j = 0, len1 = ref2.length; j < len1; j++) {
      item = ref2[j]
      results.push(parseInt(stateMap[item.state || 'no'], 10))
    }
    return results
  })()
  data.state = stateList[max(states)]
  return data
}

export const extractDataForTurnitin = function (
  submission: SubmissionWithOriginalityReport,
  key: string,
  urlPrefix: string
) {
  let data, type
  data = submission?.turnitin_data
  type = 'turnitin'
  if (data == null || submission?.vericite_data?.provider === 'vericite') {
    data = submission != null ? submission.vericite_data : undefined
    type = 'vericite'
  }
  if (submission?.has_originality_report) {
    type = 'originality_report'
  }
  if (data?.[key]?.similarity_score == null && data?.[key]?.status !== 'pending') {
    return {}
  }
  data = data[key]
  data.state = `${data.state || 'no'}_score`
  if (data.similarity_score || data.similarity_score === 0) {
    data.score = `${data.similarity_score}%`
  }
  data.reportUrl = `${urlPrefix}/assignments/${submission.assignment_id}/submissions/${submission.user_id}/${type}/${key}`
  data.tooltip = I18n.t('tooltip.score', 'Similarity Score - See detailed report')
  return data
}
