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
import type {
  AssetReportCompatibleSubmissionType,
  LtiAssetReport,
  LtiDiscussionAssetReport,
} from '../types/LtiAssetReports'

type DateTimeFormatter = (date: Date) => string

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
  formatDateTime: DateTimeFormatter,
): GroupedLtiAssetReports {
  const reportsByProc: Record<string, LtiAssetReport[]> = _.groupBy(reports, r => r.processorId)
  return processors.map(p => ({
    processor: p,
    reportGroups: reportsForAssets(
      reportsByProc[p._id] || [],
      reportsAssetSelector,
      formatDateTime,
    ),
  }))
}

function reportsForAttachmentAssets(
  reportsForProc: LtiAssetReport[],
  attachments: {_id: string; displayName: string}[],
): LtiAssetReportGroup[] {
  return attachments.map(a => ({
    key: a._id,
    displayName: a.displayName,
    reports: reportsForProc.filter(r => r.asset.attachmentId === a._id),
  }))
}

function reportsForAssets(
  reportsForProc: LtiAssetReport[],
  reportsAssetSelector: ReportsAssetSelector,
  formatDateTime: DateTimeFormatter,
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
      return reportsForAttachmentAssets(reportsForProc, attachments)
    case 'discussion_topic':
      return [
        ...reportsForAttachmentAssets(reportsForProc, attachments),
        ...discussionReports(reportsForProc, formatDateTime),
      ]
    default:
      return submissionType satisfies never
  }
}

function discussionReports(
  reportsForProc: LtiAssetReport[],
  formatDateTime: DateTimeFormatter,
): LtiAssetReportGroup[] {
  const discReports = reportsForProc.filter(isDiscussionReport)
  const grouped = _.groupBy(discReports, r => r.asset.discussionEntryVersion._id)

  const result = []
  for (const [entryId, reports] of Object.entries(grouped)) {
    const version = reports[0]?.asset.discussionEntryVersion
    const displayName = version && discussionEntryVersionDisplayName(version, formatDateTime)
    if (displayName) {
      result.push({key: entryId, displayName, reports})
    }
  }

  return result
}

function discussionEntryVersionDisplayName(
  version: LtiDiscussionAssetReport['asset']['discussionEntryVersion'],
  formatDateTime: DateTimeFormatter,
): string | undefined {
  // createdAt shouldn't actually be undefined, but type is nullable in graphql:
  if (!version.createdAt) return undefined

  const formattedDate = formatDateTime(new Date(version.createdAt))
  return I18n.t('{{date}}: "{{messageIntro}}"', {
    date: formattedDate,
    messageIntro: version.messageIntro,
  })
}

function isDiscussionReport(report: LtiAssetReport): report is LtiDiscussionAssetReport {
  return (
    report.asset.discussionEntryVersion !== null &&
    report.asset.discussionEntryVersion !== undefined
  )
}
