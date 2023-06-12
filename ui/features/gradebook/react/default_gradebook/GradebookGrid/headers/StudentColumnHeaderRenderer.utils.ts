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

import type Gradebook from '../../Gradebook'
import type {SortRowsSettingKey} from '../../gradebook.d'
import React from 'react'

export function getProps(gradebook: Gradebook, options: {ref: any}, columnHeaderName: string) {
  const columnId = columnHeaderName
  const sortRowsBySetting = gradebook.getSortRowsBySetting()
  const {columnId: currentColumnId, direction, settingKey} = sortRowsBySetting

  const studentSettingKey: SortRowsSettingKey =
    currentColumnId === columnHeaderName ? settingKey : 'sortable_name'

  const getSortKey = (): SortRowsSettingKey => {
    return columnId === 'student_firstname' ? 'name' : studentSettingKey
  }

  return {
    ref: options.ref,
    addGradebookElement: gradebook.keyboardNav?.addGradebookElement,
    disabled: !gradebook.contentLoadStates.studentsLoaded,
    loginHandleName: gradebook.options.login_handle_name,
    onHeaderKeyDown: (event: React.KeyboardEvent) => {
      gradebook.handleHeaderKeyDown(event, columnId)
    },
    onMenuDismiss() {
      setTimeout(gradebook.handleColumnHeaderMenuClose)
    },
    onSelectPrimaryInfo: gradebook.setSelectedPrimaryInfo,
    onSelectSecondaryInfo: gradebook.setSelectedSecondaryInfo,
    onToggleEnrollmentFilter: gradebook.toggleEnrollmentFilter,
    removeGradebookElement: gradebook.keyboardNav?.removeGradebookElement,
    sectionsEnabled: gradebook.sections_enabled,
    selectedEnrollmentFilters: gradebook.getSelectedEnrollmentFilters(),
    selectedPrimaryInfo: gradebook.getSelectedPrimaryInfo(),
    selectedSecondaryInfo: gradebook.getSelectedSecondaryInfo(),
    sisName: gradebook.options.sis_name,
    sortBySetting: {
      direction,
      disabled: !gradebook.contentLoadStates.studentsLoaded,
      isSortColumn: sortRowsBySetting.columnId === columnId,
      // sort functions with additional sort options enabled
      onSortBySortableName: () => {
        gradebook.setSortRowsBySetting(columnId, 'sortable_name', direction)
      },
      onSortBySisId: () => {
        gradebook.setSortRowsBySetting(columnId, 'sis_user_id', direction)
      },
      onSortByIntegrationId: () => {
        gradebook.setSortRowsBySetting(columnId, 'integration_id', direction)
      },
      onSortByLoginId: () => {
        gradebook.setSortRowsBySetting(columnId, 'login_id', direction)
      },
      onSortInAscendingOrder: () => {
        gradebook.setSortRowsBySetting(columnId, getSortKey(), 'ascending')
      },
      onSortInDescendingOrder: () => {
        gradebook.setSortRowsBySetting(columnId, getSortKey(), 'descending')
      },
      // sort functions with additional sort options disabled
      onSortBySortableNameAscending: () => {
        gradebook.setSortRowsBySetting(columnId, 'sortable_name', 'ascending')
      },
      onSortBySortableNameDescending: () => {
        gradebook.setSortRowsBySetting(columnId, 'sortable_name', 'descending')
      },
      settingKey,
    },
    studentGroupsEnabled: gradebook.studentGroupsEnabled,
  }
}
