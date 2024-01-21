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

import * as DateTimeHelpers from '@canvas/quiz-legacy-client-apps/util/date_time_helpers'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('quiz_reports')

const STUDENT_ANALYSIS = 'student_analysis'
const ITEM_ANALYSIS = 'item_analysis'
const friendlyDatetime = DateTimeHelpers.friendlyDatetime
const fudgeDateForProfileTimezone = DateTimeHelpers.fudgeDateForProfileTimezone

export default {
  getLabel(reportType) {
    if (reportType === STUDENT_ANALYSIS) {
      return I18n.t('student_analysis', 'Student Analysis')
    } else if (reportType === ITEM_ANALYSIS) {
      return I18n.t('item_analysis', 'Item Analysis')
    } else {
      return reportType
    }
  },

  getInteractionLabel(report) {
    const type = report.reportType
    let label

    if (report.isGenerated) {
      if (type === STUDENT_ANALYSIS) {
        label = I18n.t('Download student analysis report %{statusLabel}', {
          statusLabel: this.getDetailedStatusLabel(report),
        })
      } else if (type === ITEM_ANALYSIS) {
        label = I18n.t('Download item analysis report %{statusLabel}', {
          statusLabel: this.getDetailedStatusLabel(report),
        })
      }
    } else if (type === STUDENT_ANALYSIS) {
      label = I18n.t('Generate student analysis report %{statusLabel}', {
        statusLabel: this.getDetailedStatusLabel(report),
      })
    } else if (type === ITEM_ANALYSIS) {
      label = I18n.t('Generate item analysis report %{statusLabel}', {
        statusLabel: this.getDetailedStatusLabel(report),
      })
    }

    return label
  },

  getDetailedStatusLabel(report) {
    if (!report.generatable) {
      return I18n.t(
        'non_generatable_report_notice',
        'Report can not be generated for Survey Quizzes.'
      )
    } else if (report.isGenerated) {
      return I18n.t('generated_at', 'Generated: %{date}', {
        date: friendlyDatetime(fudgeDateForProfileTimezone(report.file.createdAt)),
      })
    } else if (report.isGenerating) {
      const completion = report.progress.completion

      if (completion < 50) {
        return I18n.t('generation_started', 'Report is being generated.')
      } else if (completion < 75) {
        return I18n.t('generation_halfway', 'Less than half-way to go.')
      } else {
        return I18n.t('generation_almost_done', 'Almost done.')
      }
    } else {
      return I18n.t('generatable', 'Report has never been generated.')
    }
  },
}
