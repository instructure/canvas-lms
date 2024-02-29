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
import CurveGradesDialog from '@canvas/grading/jquery/CurveGradesDialog'
import AsyncComponents from 'ui/features/gradebook/react/default_gradebook/AsyncComponents'
import CurveGradesDialogManager from 'ui/features/gradebook/react/default_gradebook/CurveGradesDialogManager'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('gradebook')

const {createCurveGradesAction} = CurveGradesDialogManager

QUnit.module('CurveGradesDialogManager.createCurveGradesAction.isDisabled', {
  props({points_possible, grades_published, grading_type, submissionsLoaded}) {
    return [
      {
        // assignment
        points_possible,
        grading_type,
        grades_published,
      },
      [], // students
      {
        isAdmin: false,
        contextUrl: 'http://contextUrl/',
        submissionsLoaded,
      },
    ]
  },
})

test(
  'is not disabled when submissions are loaded, grading type is not pass/fail and there are ' +
    'points that are not 0',
  function () {
    const props = this.props({
      points_possible: 10,
      grades_published: true,
      grading_type: 'points',
      submissionsLoaded: true,
    })
    notOk(createCurveGradesAction(...props).isDisabled)
  }
)

test('is disabled when grades are not published', function () {
  const props = this.props({
    points_possible: 10,
    grades_published: false,
    grading_type: 'points',
    submissionsLoaded: true,
  })
  ok(createCurveGradesAction(...props).isDisabled)
})

test('is disabled when submissions are not loaded', function () {
  const props = this.props({
    points_possible: 10,
    grades_published: true,
    grading_type: 'points',
    submissionsLoaded: false,
  })
  ok(createCurveGradesAction(...props).isDisabled)
})

test('is disabled when grading type is pass/fail', function () {
  const props = this.props({
    points_possible: 10,
    grades_published: true,
    grading_type: 'pass_fail',
    submissionsLoaded: true,
  })
  ok(createCurveGradesAction(...props).isDisabled)
})

test('returns true when points_possible is null', function () {
  const props = this.props({
    points_possible: null,
    grades_published: true,
    grading_type: 'points',
    submissionsLoaded: true,
  })
  ok(createCurveGradesAction(...props).isDisabled)
})

test('returns true when points_possible is 0', function () {
  const props = this.props({
    points_possible: 0,
    grades_published: true,
    grading_type: 'points',
    submissionsLoaded: true,
  })
  ok(createCurveGradesAction(...props).isDisabled)
})

QUnit.module('CurveGradesDialogManager.createCurveGradesAction.onSelect', {
  setup() {
    this.flashErrorSpy = sandbox.spy($, 'flashError')
    sandbox
      .stub(AsyncComponents, 'loadCurveGradesDialog')
      .returns(Promise.resolve(CurveGradesDialog))
    sandbox.stub(CurveGradesDialog.prototype, 'show')
  },
  async onSelect({isAdmin = false, inClosedGradingPeriod = false} = {}) {
    await createCurveGradesAction(
      {inClosedGradingPeriod},
      [],
      isAdmin,
      'http://contextUrl/',
      true
    ).onSelect()
  },
  props({inClosedGradingPeriod = false, isAdmin = false} = {}) {
    return [
      {
        // assignment
        inClosedGradingPeriod,
      },
      [], // students
      {
        isAdmin,
        contextUrl: 'http://contextUrl/',
        submissionsLoaded: true,
      },
    ]
  },
})

test('calls flashError if is not admin and in a closed grading period', async function () {
  const props = this.props({isAdmin: false, inClosedGradingPeriod: true})
  await createCurveGradesAction(...props).onSelect()
  ok(
    this.flashErrorSpy.withArgs(
      I18n.t(
        'Unable to curve grades because this assignment is due in a closed ' +
          'grading period for at least one student'
      )
    ).calledOnce
  )
})

test('does not call curve grades dialog if is not admin and in a closed grading period', async function () {
  const props = this.props({isAdmin: false, inClosedGradingPeriod: true})
  await createCurveGradesAction(...props).onSelect()
  strictEqual(CurveGradesDialog.prototype.show.callCount, 0)
})

test('does not call flashError if is admin and in a closed grading period', async function () {
  const props = this.props({isAdmin: true, inClosedGradingPeriod: true})
  await createCurveGradesAction(...props).onSelect()
  ok(this.flashErrorSpy.notCalled)
})

test('calls curve grades dialog if is admin and in a closed grading period', async function () {
  const props = this.props({isAdmin: true, inClosedGradingPeriod: true})
  await createCurveGradesAction(...props).onSelect()
  strictEqual(CurveGradesDialog.prototype.show.callCount, 1)
})

test('does not call flashError if is not admin and not in a closed grading period', async function () {
  const props = this.props({isAdmin: false, inClosedGradingPeriod: false})
  await createCurveGradesAction(...props).onSelect()
  ok(this.flashErrorSpy.notCalled)
})

test('calls curve grades dialog if is not admin and not in a closed grading period', async function () {
  const props = this.props({isAdmin: false, inClosedGradingPeriod: false})
  await createCurveGradesAction(...props).onSelect()
  strictEqual(CurveGradesDialog.prototype.show.callCount, 1)
})

test('does not call flashError if is admin and not in a closed grading period', async function () {
  const props = this.props({isAdmin: true, inClosedGradingPeriod: false})
  await createCurveGradesAction(...props).onSelect()
  ok(this.flashErrorSpy.notCalled)
})

test('calls curve grades dialog if is admin and not in a closed grading period', async function () {
  const props = this.props({isAdmin: true, inClosedGradingPeriod: false})
  await createCurveGradesAction(...props).onSelect()
  strictEqual(CurveGradesDialog.prototype.show.callCount, 1)
})
