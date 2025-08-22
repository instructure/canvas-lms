/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import _ from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'

import type {LtiAssetProcessor} from '../types/LtiAssetProcessors'
import type {AssetReportCompatibleSubmissionType, LtiAssetReport} from '../types/LtiAssetReports'

const I18n = createI18nScope('lti_asset_processor')

export type LtiAssetReportGroup = {
  key: string
  displayName: string
  reports: LtiAssetReport[]
}

type ReportsAssetSelector = {
  submissionType: AssetReportCompatibleSubmissionType
  attachments: {_id: string; displayName: string}[]
  attempt: string
}

export type GroupedLtiAssetReports = {
  processor: LtiAssetProcessor
  reportGroups: LtiAssetReportGroup[]
}[]

/**
 * Filter reports to those specified by the ReportsAssetSelector (usually
 * correspond to the assets related to one version of submission), and group as
 * they will be displayed in the component -- first by processor, then by
 * asset.
 */
export function reportsForAssetsByProcessors(
  reports: LtiAssetReport[],
  processors: LtiAssetProcessor[],
  reportsAssetSelector: ReportsAssetSelector,
): GroupedLtiAssetReports {
  const reportsByProc: Record<string, LtiAssetReport[]> = _.groupBy(reports, r => r.processorId)
  return processors.map(p => ({
    processor: p,
    reportGroups: reportsForAssets(reportsByProc[p._id] || [], reportsAssetSelector),
  }))
}

function reportsForAssets(
  reportsForProc: LtiAssetReport[],
  reportsAssetSelector: ReportsAssetSelector,
): LtiAssetReportGroup[] {
  const {submissionType, attachments, attempt} = reportsAssetSelector
  switch (submissionType) {
    case 'online_text_entry':
      return [
        {
          key: 'online_text_entry',
          displayName: I18n.t('Text submitted to Canvas'),
          reports: reportsForProc.filter(r => r.asset.submissionAttempt?.toString() === attempt),
        },
      ]
    case 'online_upload':
      return attachments.map(a => ({
        key: a._id,
        displayName: a.displayName,
        reports: reportsForProc.filter(r => r.asset.attachmentId === a._id),
      }))
    default:
      return submissionType satisfies never
  }
}
