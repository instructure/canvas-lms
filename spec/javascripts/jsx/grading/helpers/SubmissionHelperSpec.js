/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {isHidden} from 'jsx/grading/helpers/SubmissionHelper'

QUnit.module('SubmissionHelper', suiteHooks => {
  let submission

  suiteHooks.beforeEach(() => {
    submission = {
      excused: false,
      score: null,
      workflowState: 'unsubmitted'
    }
  })

  QUnit.module('.isHidden', () => {
    QUnit.module('when submission is excused', excusedHooks => {
      excusedHooks.beforeEach(() => {
        submission.excused = true
      })

      test('returns true', () => {
        strictEqual(isHidden(submission), true)
      })
    })

    QUnit.module('when submission is not excused', () => {
      test('is true when submission workflow state is graded and score is present', () => {
        submission.score = 1
        submission.workflowState = 'graded'
        strictEqual(isHidden(submission), true)
      })

      test('is false when workflow state is not graded', () => {
        submission.score = 1
        strictEqual(isHidden(submission), false)
      })

      test('is false when score is not present', () => {
        submission.workflowState = 'graded'
        strictEqual(isHidden(submission), false)
      })
    })
  })
})
