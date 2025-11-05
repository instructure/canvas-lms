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
import DateHelper from '@canvas/datetime/dateHelper'

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
        ...Object.entries(discussionReportsByEntryId(reportsForProc)).map(([entryId, reports]) => ({
          key: entryId,
          displayName: discussionAssetDisplayName(reports[0]),
          reports,
        })),
      ]
    default:
      return submissionType satisfies never
  }
}

function discussionReportsByEntryId(
  reportsForProc: LtiAssetReport[],
): Record<string, LtiDiscussionAssetReport[]> {
  const discReports: LtiDiscussionAssetReport[] = reportsForProc.filter(isDiscussionReport)
  return _.groupBy(discReports, r => r.asset.discussionEntryVersion._id)
}

function discussionAssetDisplayName(sampleReport: LtiDiscussionAssetReport) {
  const version = sampleReport.asset.discussionEntryVersion
  if (!version.createdAt) return undefined // shouldn't actually happen, but type is nullable in graphql
  const formattedDate = DateHelper.formatDatetimeForDiscussions(new Date(version.createdAt))
  return I18n.t('%{date}: "%{messageIntro}"', {
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
