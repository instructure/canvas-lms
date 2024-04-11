// @ts-nocheck
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
import TotalGradeColumnHeader from './TotalGradeColumnHeader'
import {scoreToPercentage, scoreToScaledPoints} from '@canvas/grading/GradeCalculationHelper'
import type Gradebook from '../../Gradebook'
import type GridSupport from '../GridSupport'
import type {PartialStudent} from '@canvas/grading/grading.d'
import type {Student} from '../../../../../../api.d'
import type {SendMessageArgs} from '@canvas/message-students-dialog/react/MessageStudentsWhoDialog'

function getProps(_column, gradebook: Gradebook, gridSupport: GridSupport, options) {
  const columnId = 'total_grade'
  const sortRowsBySetting = gradebook.getSortRowsBySetting()
  const pointsBased = gradebook.options.grading_standard_points_based

  const gradeSortDataLoaded =
    gradebook.assignmentsLoadedForCurrentView() &&
    gradebook.contentLoadStates.studentsLoaded &&
    gradebook.contentLoadStates.submissionsLoaded

  const columns = gridSupport.columns.getColumns()

  const isInBack = columns.scrollable[columns.scrollable.length - 1]?.id === 'total_grade'
  const isInFront = columns.frozen.some(
    (frozenColumn: {id: string}) => frozenColumn.id === 'total_grade'
  )

  let onApplyScoreToUngraded
  if (gradebook.allowApplyScoreToUngraded()) {
    onApplyScoreToUngraded = () => {
      gradebook.onApplyScoreToUngradedRequested(null)
    }
  }

  const processStudent = (student: Student): PartialStudent => {
    return {
      id: student.id,
      isInactive: Boolean(student.isInactive),
      isTestStudent: student.enrollments[0].type === 'StudentViewEnrollment',
      name: student.name,
      sortableName: student.sortable_name || '',
      submission: null,
      currentScore: pointsBased
        ? scoreToScaledPoints(
            gradebook.calculatedGradesByStudentId[student.id]?.current.score,
            gradebook.calculatedGradesByStudentId[student.id]?.current.possible,
            gradebook.options.grading_standard_scaling_factor
          )
        : scoreToPercentage(
            gradebook.calculatedGradesByStudentId[student.id]?.current.score,
            gradebook.calculatedGradesByStudentId[student.id]?.current.possible
          ),
    }
  }

  return {
    ref: options.ref,
    addGradebookElement: gradebook.keyboardNav?.addGradebookElement,
    grabFocus: gradebook.totalColumnShouldFocus(),

    gradeDisplay: {
      currentDisplay: gradebook.options.show_total_grade_as_points ? 'points' : 'percentage',
      disabled: !gradebook.contentLoadStates.submissionsLoaded,
      hidden: gradebook.weightedGrades(),
      onSelect: gradebook.togglePointsOrPercentTotals,
    },

    onHeaderKeyDown: (event: React.KeyboardEvent) => {
      gradebook.handleHeaderKeyDown(event, columnId)
    },
    onMenuDismiss() {
      setTimeout(gradebook.handleColumnHeaderMenuClose)
    },

    position: {
      isInBack,
      isInFront,
      onMoveToBack: gradebook.moveTotalGradeColumnToEnd,
      onMoveToFront: gradebook.freezeTotalGradeColumn,
    },

    onApplyScoreToUngraded,
    removeGradebookElement: gradebook.keyboardNav?.removeGradebookElement,

    showMessageStudentsWithObserversDialog:
      gradebook.options.show_message_students_with_observers_dialog,

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

    pointsBasedGradingScheme: pointsBased,
    viewUngradedAsZero: gradebook.viewUngradedAsZero(),
    isRunningScoreToUngraded: gradebook.isRunningScoreToUngraded,
    weightedGroups: gradebook.weightedGroups(),
    allStudents: Object.keys(gradebook.students).map(key =>
      processStudent(gradebook.students[key])
    ),
    courseId: gradebook.options.context_id,
    messageAttachmentUploadFolderId: gradebook.options.message_attachment_upload_folder_id,
    userId: gradebook.options.currentUserId,
    onSendMessageStudentsWho: gradebook.sendMessageStudentsWho,
  }
}

export default class TotalGradeColumnHeaderRenderer {
  gradebook: Gradebook

  constructor(gradebook: Gradebook) {
    this.gradebook = gradebook
  }

  render(column, $container: HTMLElement, gridSupport: GridSupport, options) {
    const props = getProps(column, this.gradebook, gridSupport, options)
    ReactDOM.render(<TotalGradeColumnHeader {...props} />, $container)
  }

  destroy(_column, $container: HTMLElement, _gridSupport: GridSupport) {
    ReactDOM.unmountComponentAtNode($container)
  }
}
