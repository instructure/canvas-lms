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

import React from 'react';
import ReactDOM from 'react-dom';
import AssignmentGroupColumnHeader from './AssignmentGroupColumnHeader'

function getProps (column, gradebook, options) {
  const columnId = column.id;
  const sortRowsBySetting = gradebook.getSortRowsBySetting();
  const assignmentGroup = gradebook.getAssignmentGroup(column.assignmentGroupId);

  const gradeSortDataLoaded =
    gradebook.contentLoadStates.assignmentsLoaded &&
    gradebook.contentLoadStates.studentsLoaded &&
    gradebook.contentLoadStates.submissionsLoaded;

  return {
    ref: options.ref,
    addGradebookElement: gradebook.keyboardNav.addGradebookElement,

    assignmentGroup: {
      groupWeight: assignmentGroup.group_weight,
      name: assignmentGroup.name
    },

    onHeaderKeyDown: (event) => {
      gradebook.handleHeaderKeyDown(event, columnId);
    },
    onMenuDismiss() {
      setTimeout(gradebook.handleColumnHeaderMenuClose)
    },
    removeGradebookElement: gradebook.keyboardNav.removeGradebookElement,

    sortBySetting: {
      direction: sortRowsBySetting.direction,
      disabled: !gradeSortDataLoaded,
      isSortColumn: sortRowsBySetting.columnId === columnId,
      onSortByGradeAscending: () => {
        gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
      },
      onSortByGradeDescending: () => {
        gradebook.setSortRowsBySetting(columnId, 'grade', 'descending');
      },
      settingKey: sortRowsBySetting.settingKey
    },

    weightedGroups: gradebook.weightedGroups()
  };
}

export default class AssignmentGroupColumnHeaderRenderer {
  constructor (gradebook) {
    this.gradebook = gradebook;
  }

  render (column, $container, _gridSupport, options) {
    const props = getProps(column, this.gradebook, options);
    ReactDOM.render(<AssignmentGroupColumnHeader {...props} />, $container);
  }

  destroy (column, $container, _gridSupport) {
    ReactDOM.unmountComponentAtNode($container);
  }
}
