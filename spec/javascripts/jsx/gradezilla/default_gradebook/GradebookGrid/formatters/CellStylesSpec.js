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

import {classNamesForAssignmentCell} from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/CellStyles'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid CellStyles', () => {
  let assignment
  let submissionData

  QUnit.module('.classNamesForAssignmentCell', hooks => {
    hooks.beforeEach(() => {
      assignment = {
        muted: false,
        submissionTypes: ['online_text_entry']
      }
      submissionData = {
        dropped: false,
        excused: false,
        late: false,
        missing: false,
        resubmitted: false
      }
    })

    test('returns an empty array for an "ordinary" assignment and submission', () => {
      deepEqual(classNamesForAssignmentCell(assignment, submissionData), [])
    })

    test('returns an empty array when there is no submission data', () => {
      // This should never occur, but is an appropriate case to cover.
      deepEqual(classNamesForAssignmentCell(assignment, null), [])
    })

    test('includes "dropped" when the submission has been dropped', () => {
      submissionData.dropped = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['dropped'])
    })

    test('includes "excused" when the submission has been excused', () => {
      submissionData.excused = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['excused'])
    })

    test('does not include "excused" when the submission was also dropped', () => {
      // While this is not a realistic case, covering this explicitly results in
      // easier enforcement of the exclusive styles.
      submissionData.excused = true
      submissionData.dropped = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['dropped'])
    })

    test('includes "resubmitted" when the submission has been resubmitted', () => {
      submissionData.resubmitted = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['resubmitted'])
    })

    test('does not include "resubmitted" when the submission was also excused', () => {
      submissionData.excused = true
      submissionData.resubmitted = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['excused'])
    })

    test('does not include "resubmitted" when the submission was also dropped', () => {
      submissionData.dropped = true
      submissionData.resubmitted = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['dropped'])
    })

    test('includes "missing" when the submission is missing', () => {
      submissionData.missing = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['missing'])
    })

    test('does not include "missing" when the submission was also resubmitted', () => {
      // While this is not a realistic case, covering this explicitly results in
      // easier enforcement of the exclusive styles.
      submissionData.resubmitted = true
      submissionData.missing = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['resubmitted'])
    })

    test('does not include "missing" when the submission was also excused', () => {
      submissionData.excused = true
      submissionData.missing = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['excused'])
    })

    test('does not include "missing" when the submission was also dropped', () => {
      submissionData.dropped = true
      submissionData.missing = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['dropped'])
    })

    test('includes "late" when the submission is missing', () => {
      submissionData.late = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['late'])
    })

    test('does not include "late" when the submission is also missing', () => {
      submissionData.missing = true
      submissionData.late = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['missing'])
    })

    test('does not include "late" when the submission was also resubmitted', () => {
      submissionData.resubmitted = true
      submissionData.late = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['resubmitted'])
    })

    test('does not include "late" when the submission was also excused', () => {
      submissionData.excused = true
      submissionData.late = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['excused'])
    })

    test('does not include "late" when the submission was also dropped', () => {
      submissionData.dropped = true
      submissionData.late = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['dropped'])
    })

    test('includes "ungraded" when the assignment is not graded', () => {
      assignment.submissionTypes = ['not_graded']
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['ungraded'])
    })

    test('includes "ungraded" when the assignment is not graded', () => {
      assignment.submissionTypes = ['not_graded']
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['ungraded'])
    })

    test('includes "muted" when the assignment is muted', () => {
      assignment.muted = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['muted'])
    })

    test('assignment classNames are not exclusive', () => {
      assignment.submissionTypes = ['not_graded']
      assignment.muted = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['ungraded', 'muted'])
    })

    test('assignment classNames are not exclusive with submission classNames', () => {
      submissionData.dropped = true
      assignment.submissionTypes = ['not_graded']
      assignment.muted = true
      const classNames = classNamesForAssignmentCell(assignment, submissionData)
      deepEqual(classNames, ['dropped', 'ungraded', 'muted'])
    })
  })
})
/* eslint-enable qunit/no-identical-names */
