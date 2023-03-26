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

import type {CamelizedGradingPeriodSet} from '@canvas/grading/grading.d'
import type {Module} from '../../../../../api.d'
import type {ColumnOrderSettings, GradebookStudent} from '../gradebook.d'

export const DEFAULT_COLUMN_SORT_TYPE = 'assignment_group'

export function hideAggregateColumns(
  gradingPeriodSet: CamelizedGradingPeriodSet | null,
  gradingPeriodId: string
) {
  if (gradingPeriodSet == null) {
    return false
  }
  if (gradingPeriodSet.displayTotalsForAllGradingPeriods) {
    return false
  }
  return gradingPeriodId === '0'
}

export function isFilteringColumnsByGradingPeriod(gradingPeriodId: string) {
  return gradingPeriodId !== '0'
}

export function isInvalidSort(
  modules: Module[],
  gradebookColumnOrderSettings: ColumnOrderSettings | undefined
) {
  const sortSettings = gradebookColumnOrderSettings
  if (
    (sortSettings != null ? sortSettings.sortType : undefined) === 'custom' &&
    !(sortSettings != null ? sortSettings.customOrder : undefined)
  ) {
    // This course was sorted by a custom column sort at some point but no longer has any stored
    // column order to sort by
    // let's mark it invalid so it reverts to default sort
    return true
  }
  if (sortSettings?.sortType === 'module_position' && modules.length === 0) {
    // This course was sorted by module_position at some point but no longer contains modules
    // let's mark it invalid so it reverts to default sort
    return true
  }
  return false
}

export function getColumnOrder(
  modules: Module[],
  gradebookColumnOrderSettings: ColumnOrderSettings | undefined
): ColumnOrderSettings {
  if (isInvalidSort(modules, gradebookColumnOrderSettings) || !gradebookColumnOrderSettings) {
    return {
      direction: 'ascending',
      freezeTotalGrade: false,
      sortType: DEFAULT_COLUMN_SORT_TYPE,
    }
  } else {
    return gradebookColumnOrderSettings
  }
}

export function listRowIndicesForStudentIds(
  rows: GradebookStudent,
  studentIds: string[]
): number[] {
  const rowIndicesByStudentId = rows.reduce(
    (
      map: {
        [studentId: string]: number
      },
      row: GradebookStudent,
      index: number
    ) => {
      map[row.id] = index
      return map
    },
    {}
  )
  return studentIds.map(studentId => rowIndicesByStudentId[studentId])
}
