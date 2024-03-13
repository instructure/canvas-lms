/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import UserSettings from '@canvas/user-settings'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

const $fixtures = document.getElementById('fixtures')

QUnit.module('#switchTotalDisplay()', hooks => {
  let gradebook
  hooks.beforeEach(() => {
    setFixtureHtml($fixtures)

    // Stub this here so the AJAX calls in Dataloader don't get stubbed too
    sandbox.stub($, 'ajaxJSON')

    createAndStubGradebook()
  })

  hooks.afterEach(() => {
    UserSettings.contextRemove('warned_about_totals_display')
    gradebook.destroy()
    $fixtures.innerHTML = ''
  })

  function createAndStubGradebook() {
    gradebook = createGradebook({
      show_total_grade_as_points: true,
      setting_update_url: 'http://settingUpdateUrl',
    })

    gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub(),
      },
    }

    sandbox.stub(gradebook.gradebookGrid, 'invalidate')
  }

  test('sets the warned_about_totals_display setting when called with true', () => {
    notOk(UserSettings.contextGet('warned_about_totals_display'))
    gradebook.switchTotalDisplay({dontWarnAgain: true})
    strictEqual(UserSettings.contextGet('warned_about_totals_display'), true)
  })

  test('show_total_grade_as_points env is mutable', () => {
    const originalValue = gradebook.options.show_total_grade_as_points
    gradebook.options.show_total_grade_as_points = !gradebook.options.show_total_grade_as_points
    notEqual(originalValue, gradebook.options.show_total_grade_as_points)
  })

  test('disables "Show Total Grade as Points" when previously enabled', () => {
    gradebook.switchTotalDisplay({dontWarnAgain: false})
    strictEqual(gradebook.options.show_total_grade_as_points, false)
  })

  test('enables "Show Total Grade as Points" when previously disabled', () => {
    gradebook.switchTotalDisplay({dontWarnAgain: false})
    gradebook.switchTotalDisplay({dontWarnAgain: false})
    strictEqual(gradebook.options.show_total_grade_as_points, true)
  })

  test('updates the total display preferences for the current user', () => {
    gradebook.switchTotalDisplay({dontWarnAgain: false})

    strictEqual($.ajaxJSON.callCount, 1)
    equal($.ajaxJSON.getCall(0).args[0], 'http://settingUpdateUrl')
    equal($.ajaxJSON.getCall(0).args[1], 'PUT')
    strictEqual($.ajaxJSON.getCall(0).args[2].show_total_grade_as_points, false)
  })

  test('invalidates the grid so it re-renders it', () => {
    gradebook.switchTotalDisplay({dontWarnAgain: false})
    strictEqual(gradebook.gradebookGrid.invalidate.callCount, 1)
  })

  test('updates column headers', () => {
    gradebook.switchTotalDisplay({dontWarnAgain: false})
    strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
  })

  QUnit.module('when the "total grade override" column is used', () => {
    test('includes both "total grade" column ids when updating column headers', () => {
      gradebook.courseSettings.setAllowFinalGradeOverride(true)
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      const [columnIds] =
        gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
      deepEqual(columnIds, ['total_grade', 'total_grade_override'])
    })
  })

  QUnit.module('when the "total grade override" column is not used', () => {
    test('includes only the "total grade" column id when updating column headers', () => {
      gradebook.courseSettings.setAllowFinalGradeOverride(false)
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      const [columnIds] =
        gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
      deepEqual(columnIds, ['total_grade'])
    })
  })
})

QUnit.module('Gradebook#togglePointsOrPercentTotals', {
  setup() {
    this.gradebook = createGradebook({
      show_total_grade_as_points: true,
      setting_update_url: 'http://settingUpdateUrl',
    })
    sandbox.stub(this.gradebook, 'switchTotalDisplay')

    // Stub this here so the AJAX calls in Dataloader don't get stubbed too
    sandbox.stub($, 'ajaxJSON')
  },

  teardown() {
    UserSettings.contextRemove('warned_about_totals_display')
    $('.ui-dialog').remove()
  },
})

test('when user is ignoring warnings, immediately toggles the total grade display', function () {
  UserSettings.contextSet('warned_about_totals_display', true)

  this.gradebook.togglePointsOrPercentTotals()

  equal(this.gradebook.switchTotalDisplay.callCount, 1, 'toggles the total grade display')
})

test('when user is ignoring warnings and a callback is given, immediately invokes callback', function () {
  const callback = sinon.stub()
  UserSettings.contextSet('warned_about_totals_display', true)

  this.gradebook.togglePointsOrPercentTotals(callback)

  equal(callback.callCount, 1)
})

test('when user is not ignoring warnings, return a dialog', function () {
  UserSettings.contextSet('warned_about_totals_display', false)

  const dialog = this.gradebook.togglePointsOrPercentTotals()

  equal(
    dialog.constructor.name,
    'GradeDisplayWarningDialog',
    'returns a grade display warning dialog'
  )

  dialog.cancel()
})

test('when user is not ignoring warnings, the dialog has a save property which is the switchTotalDisplay function', function () {
  sandbox.stub(UserSettings, 'contextGet').withArgs('warned_about_totals_display').returns(false)
  const dialog = this.gradebook.togglePointsOrPercentTotals()

  equal(dialog.options.save, this.gradebook.switchTotalDisplay)

  dialog.cancel()
})

test('when user is not ignoring warnings, the dialog has a onClose property which is the callback function', function () {
  const callback = sinon.stub()
  sandbox.stub(UserSettings, 'contextGet').withArgs('warned_about_totals_display').returns(false)
  const dialog = this.gradebook.togglePointsOrPercentTotals(callback)

  equal(dialog.options.onClose, callback)

  dialog.cancel()
})
