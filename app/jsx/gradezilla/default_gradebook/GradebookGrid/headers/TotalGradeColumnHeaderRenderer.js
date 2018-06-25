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
import TotalGradeColumnHeader from './TotalGradeColumnHeader'

function getProps (column, gradebook, gridSupport, options) {
  const columnId = 'total_grade';
  const sortRowsBySetting = gradebook.getSortRowsBySetting();

  const gradeSortDataLoaded =
    gradebook.contentLoadStates.assignmentsLoaded &&
    gradebook.contentLoadStates.studentsLoaded &&
    gradebook.contentLoadStates.submissionsLoaded;

  const columns = gridSupport.columns.getColumns();

  const isInBack = columns.scrollable[columns.scrollable.length - 1].id === 'total_grade';
  const isInFront = columns.frozen.some(frozenColumn => frozenColumn.id === 'total_grade');

  return {
    ref: options.ref,
    addGradebookElement: gradebook.keyboardNav.addGradebookElement,
    grabFocus: gradebook.totalColumnShouldFocus(),

    gradeDisplay: {
      currentDisplay: gradebook.options.show_total_grade_as_points ? 'points' : 'percentage',
      disabled: !gradebook.contentLoadStates.submissionsLoaded,
      hidden: gradebook.weightedGrades(),
      onSelect: gradebook.togglePointsOrPercentTotals
    },

    onHeaderKeyDown: (event) => {
      gradebook.handleHeaderKeyDown(event, columnId);
    },
    onMenuDismiss: gradebook.handleColumnHeaderMenuClose,

    position: {
      isInBack,
      isInFront,
      onMoveToBack: gradebook.moveTotalGradeColumnToEnd,
      onMoveToFront: gradebook.freezeTotalGradeColumn
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

export default class TotalGradeColumnHeaderRenderer {
  constructor (gradebook) {
    this.gradebook = gradebook;
  }

  render (column, $container, gridSupport, options) {
    const props = getProps(column, this.gradebook, gridSupport, options);
    ReactDOM.render(<TotalGradeColumnHeader {...props} />, $container);
  }

  destroy (_column, $container, _gridSupport) {
    ReactDOM.unmountComponentAtNode($container);
  }
}
