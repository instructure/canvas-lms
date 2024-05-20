/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {defaultColors} from '@canvas/grading-status-list-item'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'
import type {GradingStatusQueryResult} from '../types/accountStatusQueries'

const I18n = useI18nScope('account_grading_settings')

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

export const mapCustomStatusQueryResults = (
  customStatuses: GradingStatusQueryResult[]
): GradeStatus[] => {
  return customStatuses.map((status: GradingStatusQueryResult) => ({
    id: status.id,
    name: status.name,
    color: status.color,
    type: 'custom',
  }))
}

export const mapStandardStatusQueryResults = (
  standardStatuses: GradingStatusQueryResult[],
  isExtendedStatusEnabled?: boolean
): GradeStatus[] => {
  const defaultStandardStatuses = {...DefaultStandardStatusesMap}

  for (const status of standardStatuses) {
    const {id, color} = status
    const {name: defaultName} = defaultStandardStatuses[status.name]
    defaultStandardStatuses[status.name] = {
      id,
      name: defaultName,
      color,
    }
  }

  if (!isExtendedStatusEnabled) {
    delete defaultStandardStatuses.extended
  }

  return Object.values(defaultStandardStatuses)
}

const DefaultStandardStatusesMap: Record<string, GradeStatus> = {
  late: {
    id: '-1',
    name: 'late',
    color: defaultColors.blue,
    isNew: true,
  },
  missing: {
    id: '-2',
    name: 'missing',
    color: defaultColors.salmon,
    isNew: true,
  },
  resubmitted: {
    id: '-3',
    name: 'resubmitted',
    color: defaultColors.green,
    isNew: true,
  },
  dropped: {
    id: '-4',
    name: 'dropped',
    color: defaultColors.orange,
    isNew: true,
  },
  excused: {
    id: '-5',
    name: 'excused',
    color: defaultColors.yellow,
    isNew: true,
  },
  extended: {
    id: '-6',
    name: 'extended',
    color: defaultColors.lavender,
    isNew: true,
  },
}
