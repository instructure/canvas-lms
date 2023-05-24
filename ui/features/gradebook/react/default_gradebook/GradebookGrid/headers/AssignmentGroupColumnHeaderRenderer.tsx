/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import AssignmentGroupColumnHeader from './AssignmentGroupColumnHeader'
import type GridSupport from '../GridSupport/index'
import type Gradebook from '../../Gradebook'

function getProps(column, gradebook: Gradebook, options) {
  const columnId = column.id
  const sortRowsBySetting = gradebook.getSortRowsBySetting()
  const assignmentGroup = gradebook.getAssignmentGroup(column.assignmentGroupId)

  const gradeSortDataLoaded =
    gradebook.assignmentsLoadedForCurrentView() &&
    gradebook.contentLoadStates.studentsLoaded &&
    gradebook.contentLoadStates.submissionsLoaded

  let onApplyScoreToUngraded
  if (gradebook.allowApplyScoreToUngraded()) {
    onApplyScoreToUngraded = () => {
      gradebook.onApplyScoreToUngradedRequested(assignmentGroup)
    }
  }
  return {
    ref: options.ref,
    addGradebookElement: gradebook.keyboardNav?.addGradebookElement,

    assignmentGroup: {
      groupWeight: assignmentGroup.group_weight,
      name: assignmentGroup.name,
    },

    onApplyScoreToUngraded,
    onHeaderKeyDown: event => {
      gradebook.handleHeaderKeyDown(event, columnId)
    },
    onMenuDismiss() {
      setTimeout(gradebook.handleColumnHeaderMenuClose)
    },
    removeGradebookElement: gradebook.keyboardNav?.removeGradebookElement,

    sortBySetting: {
      direction: sortRowsBySetting.direction,
      disabled: !gradeSortDataLoaded,
      isSortColumn: sortRowsBySetting.columnId === columnId,
      onSortByGradeAscending: () => {
        gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending')
      },
      onSortByGradeDescending: () => {
        gradebook.setSortRowsBySetting(columnId, 'grade', 'descending')
      },
      settingKey: sortRowsBySetting.settingKey,
    },

    viewUngradedAsZero: gradebook.viewUngradedAsZero(),
    isRunningScoreToUngraded: gradebook.isRunningScoreToUngraded,
    weightedGroups: gradebook.weightedGroups(),
  }
}

export default class AssignmentGroupColumnHeaderRenderer {
  gradebook: Gradebook

  constructor(gradebook: Gradebook) {
    this.gradebook = gradebook
  }

  render(column, $container: HTMLElement, _gridSupport: GridSupport, options) {
    const props = getProps(column, this.gradebook, options)
    ReactDOM.render(<AssignmentGroupColumnHeader {...props} />, $container)
  }

  destroy(_column, $container: HTMLElement, _gridSupport: GridSupport) {
    ReactDOM.unmountComponentAtNode($container)
  }
}
