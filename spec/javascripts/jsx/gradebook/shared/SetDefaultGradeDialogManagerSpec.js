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

import $ from 'jquery'
import 'jquery-migrate'

import SetDefaultGradeDialog from '@canvas/grading/jquery/SetDefaultGradeDialog'
import SetDefaultGradeDialogManager from 'ui/features/gradebook/react/shared/SetDefaultGradeDialogManager'
import AsyncComponents from 'ui/features/gradebook/react/default_gradebook/AsyncComponents'

function createAssignmentProp() {
  return {
    id: '1',
    grades_published: true,
    html_url: 'http://assignment_htmlUrl',
    invalid: false,
    muted: false,
    name: 'Assignment #1',
    omit_from_final_grade: false,
    points_possible: 13,
    submission_types: ['online_text_entry'],
    course_id: '42',
  }
}

function createGetStudentsProp() {
  return _assignmentId => [
    {
      id: '11',
      name: 'Clark Kent',
      isInactive: false,
      submission: {
        score: 7,
        submittedAt: null,
      },
    },
    {
      id: '13',
      name: 'Barry Allen',
      isInactive: false,
      submission: {
        score: 8,
        submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)'),
      },
    },
    {
      id: '15',
      name: 'Bruce Wayne',
      isInactive: false,
      submission: {
        score: undefined,
        submittedAt: undefined,
      },
    },
  ]
}

QUnit.module('SetDefaultGradeDialogManager#isDialogEnabled')

test('returns true when submissions are loaded', () => {
  const manager = new SetDefaultGradeDialogManager(
    createAssignmentProp(),
    createGetStudentsProp(),
    'contextId',
    true,
    'selectedSection',
    false,
    true
  )

  ok(manager.isDialogEnabled())
})

test('returns false when submissions are not loaded', () => {
  const manager = new SetDefaultGradeDialogManager(
    createAssignmentProp(),
    createGetStudentsProp(),
    'contextId',
    true,
    'selectedSection',
    false,
    false
  )

  notOk(manager.isDialogEnabled())
})

test('returns false when grades are not published', () => {
  const manager = new SetDefaultGradeDialogManager(
    {...createAssignmentProp(), grades_published: false},
    createGetStudentsProp(),
    'contextId',
    true,
    'selectedSection',
    false,
    true
  )

  notOk(manager.isDialogEnabled())
})

QUnit.module('SetDefaultGradeDialogManager#showDialog', {
  setupDialogManager(opts) {
    const assignment = {
      ...createAssignmentProp(),
      // Yes, some of the keys are snake-case, whereas others are camel-case ;(
      inClosedGradingPeriod: opts.inClosedGradingPeriod,
    }

    return new SetDefaultGradeDialogManager(
      assignment,
      createGetStudentsProp(),
      'contextId',
      true,
      'selectedSection',
      opts.isAdmin,
      true
    )
  },

  setup() {
    this.flashErrorStub = sandbox.stub($, 'flashError')
    sandbox
      .stub(AsyncComponents, 'loadSetDefaultGradeDialog')
      .returns(Promise.resolve(SetDefaultGradeDialog))
    this.showDialogStub = sandbox.stub(SetDefaultGradeDialog.prototype, 'show')
  },
})

test('shows the SetDefaultGradeDialog when assignment is not in a closed grading period', async function () {
  const manager = this.setupDialogManager({inClosedGradingPeriod: false, isAdmin: false})
  await manager.showDialog()

  equal(this.showDialogStub.callCount, 1)
})

test('does not show an error when assignment is not in a closed grading period', async function () {
  const manager = this.setupDialogManager({inClosedGradingPeriod: false, isAdmin: false})
  await manager.showDialog()

  equal(this.flashErrorStub.callCount, 0)
})

test('shows the SetDefaultGradeDialog when assignment is in a closed grading period but isAdmin is true', async function () {
  const manager = this.setupDialogManager({inClosedGradingPeriod: true, isAdmin: true})
  await manager.showDialog()

  equal(this.showDialogStub.callCount, 1)
})

test('does not show an error when assignment is in a closed grading period but isAdmin is true', async function () {
  const manager = this.setupDialogManager({inClosedGradingPeriod: true, isAdmin: true})
  await manager.showDialog()

  equal(this.flashErrorStub.callCount, 0)
})

test('shows an error message when assignment is in a closed grading period and isAdmin is false', async function () {
  const manager = this.setupDialogManager({inClosedGradingPeriod: true, isAdmin: false})
  await manager.showDialog()

  equal(this.flashErrorStub.callCount, 1)
})

test('does not show the SetDefaultGradeDialog when assignment is in a closed grading period and isAdmin is false', async function () {
  const manager = this.setupDialogManager({inClosedGradingPeriod: true, isAdmin: false})
  await manager.showDialog()

  equal(this.showDialogStub.callCount, 0)
})
