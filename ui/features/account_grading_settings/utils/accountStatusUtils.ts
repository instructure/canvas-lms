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

import {GradingStatusQueryResult} from '../types/accountStatusQueries'
import {GradeStatus} from '../types/gradingStatus'

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
  standardStatuses: GradingStatusQueryResult[]
): GradeStatus[] => {
  const defaultStandardStatuses = {...DefaultStandardStatusesMap}

  for (const status of standardStatuses) {
    const {id, color} = status
    const {name: defaultName} = defaultStandardStatuses[status.name]
    defaultStandardStatuses[status.name] = {
      id,
      name: defaultName,
      color,
      type: 'standard',
    }
  }

  return Object.values(defaultStandardStatuses)
}

const DefaultStandardStatusesMap: Record<string, GradeStatus> = {
  late: {
    id: '-1',
    name: 'Late',
    color: '#E5F7E5',
    type: 'standard',
    isNew: true,
  },
  missing: {
    id: '-2',
    name: 'Missing',
    color: '#FFE8E5',
    type: 'standard',
    isNew: true,
  },
  resubmitted: {
    id: '-3',
    name: 'Resubmitted',
    color: '#E9EDF5',
    type: 'standard',
    isNew: true,
  },
  dropped: {
    id: '-4',
    name: 'Dropped',
    color: '#FEF0E5',
    type: 'standard',
    isNew: true,
  },
  excused: {
    id: '-5',
    name: 'Excused',
    color: '#FEF7E5',
    type: 'standard',
    isNew: true,
  },
  standard: {
    id: '-6',
    name: 'Extended',
    color: '#E5F3FC',
    type: 'standard',
    isNew: true,
  },
}
