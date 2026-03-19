/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import statusLateUrl from './icons/late.svg'
import statusMissingUrl from './icons/missing.svg'
import statusResubmittedUrl from './icons/resubmitted.svg'
import statusDroppedUrl from './icons/dropped.svg'
import statusExcusedUrl from './icons/excused.svg'
import statusExtendedUrl from './icons/extended.svg'
import statusCustom1Url from './icons/custom-1.svg'
import statusCustom2Url from './icons/custom-2.svg'
import statusCustom3Url from './icons/custom-3.svg'
import {GradeStatusUnderscore} from './accountGradingStatus'
import {SubmissionData} from './grading'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('gradebook')

export const statusesTitleMap: {
  late: string
  missing: string
  resubmitted: string
  dropped: string
  excused: string
  extended: string
} = {
  late: I18n.t('Late'),
  missing: I18n.t('Missing'),
  resubmitted: I18n.t('Resubmitted'),
  dropped: I18n.t('Dropped'),
  excused: I18n.t('Excused'),
  extended: I18n.t('Extended'),
} as const

export const STATUS_ICONS: Record<string, string> = {
  late: statusLateUrl,
  missing: statusMissingUrl,
  resubmitted: statusResubmittedUrl,
  dropped: statusDroppedUrl,
  excused: statusExcusedUrl,
  extended: statusExtendedUrl,
  'custom-1': statusCustom1Url,
  'custom-2': statusCustom2Url,
  'custom-3': statusCustom3Url,
}

export type StatusIconInfo = {
  iconUrl: string
  title: string
}

export function getStatusIcon(
  submissionData: SubmissionData,
  customGradeStatuses: GradeStatusUnderscore[] = [],
): StatusIconInfo | undefined {
  if (submissionData.dropped) {
    return {iconUrl: STATUS_ICONS.dropped, title: statusesTitleMap.dropped}
  }
  if (submissionData.excused) {
    return {iconUrl: STATUS_ICONS.excused, title: statusesTitleMap.excused}
  }
  if (submissionData.extended) {
    return {iconUrl: STATUS_ICONS.extended, title: statusesTitleMap.extended}
  }
  if (submissionData.late) {
    return {iconUrl: STATUS_ICONS.late, title: statusesTitleMap.late}
  }
  if (submissionData.resubmitted) {
    return {iconUrl: STATUS_ICONS.resubmitted, title: statusesTitleMap.resubmitted}
  }
  if (submissionData.missing) {
    return {iconUrl: STATUS_ICONS.missing, title: statusesTitleMap.missing}
  }
  if (submissionData.customGradeStatusId) {
    const customStatusesForSubmissions = customGradeStatuses.filter(
      status => status.applies_to_submissions,
    )
    const customStatus = customStatusesForSubmissions.find(
      status => status.id === submissionData.customGradeStatusId,
    )

    if (customStatus?.icon) {
      return {
        iconUrl: STATUS_ICONS[customStatus.icon],
        title: customStatus.name,
      }
    }
  }
  return undefined
}
