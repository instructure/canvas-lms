/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import fakeENV from 'helpers/fakeENV'
import GradebookHeaderMenu from 'compiled/gradebook/GradebookHeaderMenu'
import SetDefaultGradeDialog from 'compiled/gradebook/SetDefaultGradeDialog'
import CurveGradesDialog from 'compiled/shared/CurveGradesDialog'

QUnit.module('GradebookHeaderMenu#menuPopupOpenHandler', {
  setup() {
    this.menuPopupOpenHandler = GradebookHeaderMenu.prototype.menuPopupOpenHandler
    this.hideMenuActionsWithUnmetDependencies = this.stub()
    this.disableUnavailableMenuActions = this.stub()
    this.menu = 'mockMenu'
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('calls @hideMenuActionsWithUnmetDependencies when isAdmin', function() {
  fakeENV.setup({current_user_roles: ['admin']})
  this.menuPopupOpenHandler()
  ok(this.hideMenuActionsWithUnmetDependencies.called)
})

test('calls @hideMenuActionsWithUnmetDependencies when not isAdmin', function() {
  fakeENV.setup({current_user_roles: []})
  this.menuPopupOpenHandler()
  ok(this.hideMenuActionsWithUnmetDependencies.called)
})

test('does not call @disableUnavailableMenuActions when isAdmin', function() {
  fakeENV.setup({current_user_roles: ['admin']})
  this.menuPopupOpenHandler()
  notOk(this.disableUnavailableMenuActions.called)
})

test('calls @disableUnavailableMenuActions when not isAdmin', function() {
  fakeENV.setup({current_user_roles: []})
  this.menuPopupOpenHandler()
  ok(this.disableUnavailableMenuActions.called)
})

QUnit.module('GradebookHeaderMenu#hideMenuActionsWithUnmetDependencies', {
  setup() {
    fakeENV.setup()
    this.hideMenuActionsWithUnmetDependencies =
      GradebookHeaderMenu.prototype.hideMenuActionsWithUnmetDependencies

    // These are all set to ensure all options are visible by default
    this.allSubmissionsLoaded = true
    this.assignment = {
      grading_type: 'not pass_fail',
      points_possible: 10,
      submission_types: 'online_upload',
      has_submitted_submissions: true,
      submissions_downloads: 1
    }
    this.gradebook = {options: {gradebook_is_editable: true}}
    this.menuElement = document.createElement('ul')
    this.createMenu(this.menuElement)
    this.menu = $(this.menuElement)
  },
  teardown() {
    fakeENV.teardown()
  },
  createMenu(root) {
    const menuItems = [
      'showAssignmentDetails',
      'messageStudentsWho',
      'setDefaultGrade',
      'curveGrades',
      'downloadSubmissions',
      'reuploadSubmissions'
    ]
    menuItems.forEach(item => {
      const menuItem = document.createElement('li')
      menuItem.setAttribute('data-action', item)
      root.appendChild(menuItem)
    })
  },
  visibleMenuItems(root) {
    return root.find('li:not([style*="display: none"])')
  },
  visibleMenuItemNames(root) {
    return Array.from(this.visibleMenuItems(root)).map(item => item.getAttribute('data-action'))
  }
})

test('hides 0 menu items given optimal conditions', function() {
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  equal(this.visibleMenuItems(this.menu).length, 6)
})

test('hides the showAssignmentDetails menu item when @allSubmissionsLoaded is false', function() {
  this.allSubmissionsLoaded = false
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('showAssignmentDetails'))
})

test('hides the messageStudentsWho menu item when @allSubmissionsLoaded is false', function() {
  this.allSubmissionsLoaded = false
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('messageStudentsWho'))
})

test('hides the setDefaultGrade menu item when @allSubmissionsLoaded is false', function() {
  this.allSubmissionsLoaded = false
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('setDefaultGrade'))
})

test('hides the curveGrades menu item when @allSubmissionsLoaded is false', function() {
  this.allSubmissionsLoaded = false
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('curveGrades'))
})

test('hides the curveGrades menu item when @assignment.grading_type is pass_fail', function() {
  this.assignment.grading_type = 'pass_fail'
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('curveGrades'))
})

test('hides the curveGrades menu item when @assignment.points_possible is empty', function() {
  delete this.assignment.points_possible
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('curveGrades'))
})

test('hides the curveGrades menu item when @assignment.points_possible is 0', function() {
  this.assignment.points_possible = 0
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('curveGrades'))
})

test('does not hide the downloadSubmissions menu item when @assignment.submission_types is online_text_entry or online_url', function() {
  ;['online_text_entry', 'online_url'].forEach(submission_type => {
    this.assignment.submission_types = 'online_text_entry'
    this.hideMenuActionsWithUnmetDependencies(this.menu)
    ok(this.visibleMenuItemNames(this.menu).includes('downloadSubmissions'))
  })
})

test('hides the downloadSubmissions menu item when @assignment.submission_types is not one of online_upload, online_text_entry or online_url', function() {
  this.assignment.submission_types = 'go-ravens'
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('downloadSubmissions'))
})

test('hides the reuploadSubmissions menu item when gradebook is editable', function() {
  this.gradebook.options.gradebook_is_editable = false
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('reuploadSubmissions'))
})

test('hides the reuploadSubmissions menu item when @assignment.submission_downloads is 0', function() {
  this.assignment.submissions_downloads = 0
  this.hideMenuActionsWithUnmetDependencies(this.menu)
  notOk(this.visibleMenuItemNames(this.menu).includes('reuploadSubmissions'))
})

QUnit.module('GradebookHeaderMenu#disableUnavailableMenuActions', {
  setup() {
    fakeENV.setup({GRADEBOOK_OPTIONS: {has_grading_periods: true}})
    this.disableUnavailableMenuActions = GradebookHeaderMenu.prototype.disableUnavailableMenuActions
    this.menuElement = document.createElement('ul')
    this.createMenu(this.menuElement)
    this.menu = $(this.menuElement)
  },
  teardown() {
    fakeENV.teardown()
  },
  createMenu(root) {
    const menuItems = ['first', 'second', 'curveGrades', 'setDefaultGrade', 'fifth']
    menuItems.forEach(item => {
      const menuItem = document.createElement('li')
      menuItem.setAttribute('data-action', item)
      root.appendChild(menuItem)
    })
  },
  disabledMenuItems(root) {
    return root.find('.ui-state-disabled')
  }
})

test('disables 0 menu items when given a menu but @assignment does not exist', function() {
  this.disableUnavailableMenuActions(this.menu)
  equal(this.disabledMenuItems(this.menu).length, 0)
})

test('disables 0 menu items when given a menu and @assignment which does not have inClosedGradingPeriod set', function() {
  this.assignment = {}
  this.disableUnavailableMenuActions(this.menu)
  equal(this.disabledMenuItems(this.menu).length, 0)
})

test('disables 0 menu items when given a menu and @assignment which has inClosedGradingPeriod set', function() {
  this.assignment = {inClosedGradingPeriod: false}
  this.disableUnavailableMenuActions(this.menu)
  equal(this.disabledMenuItems(this.menu).length, 0)
})

test('given an assignment in closed grading period, disable curveGrades and setDefaultGrade menu items', function() {
  this.assignment = {inClosedGradingPeriod: true}
  this.disableUnavailableMenuActions(this.menu)
  const disabledMenuItems = this.disabledMenuItems(this.menu)
  equal(disabledMenuItems.length, 2)
  equal(disabledMenuItems[0].getAttribute('data-action'), 'curveGrades')
  equal(disabledMenuItems[1].getAttribute('data-action'), 'setDefaultGrade')
  ok(disabledMenuItems[0].getAttribute('aria-disabled'))
  ok(disabledMenuItems[1].getAttribute('aria-disabled'))
})

QUnit.module('GradebookHeaderMenu#setDefaultGrade', {
  setup() {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {has_grading_periods: true},
      current_user_roles: ['admin']
    })
    this.setDefaultGrade = GradebookHeaderMenu.prototype.setDefaultGrade
    this.options = {assignment: {inClosedGradingPeriod: false}}
    this.spy($, 'flashError')
    this.dialogStub = this.stub(SetDefaultGradeDialog.prototype, 'show')
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('calls the SetDefaultGradeDialog when isAdmin is true and assignment has no due date in a closed grading period', function() {
  this.setDefaultGrade(this.options)
  ok(this.dialogStub.called)
})

test('calls the SetDefaultGradeDialog when isAdmin is true and assignment does have a due date in a closed grading period', function() {
  this.options.assignment.inClosedGradingPeriod = true
  this.setDefaultGrade(this.options)
  ok(this.dialogStub.called)
})

test('calls the SetDefaultGradeDialog when isAdmin is false and assignment has no due date in a closed grading period', function() {
  ENV.current_user_roles = []
  this.setDefaultGrade(this.options)
  ok(this.dialogStub.called)
})

test('calls the flashError when isAdmin is false and assignment does have a due date in a closed grading period', function() {
  ENV.current_user_roles = []
  this.options.assignment.inClosedGradingPeriod = true
  this.setDefaultGrade(this.options)
  notOk(this.dialogStub.called)
  ok($.flashError.called)
})

QUnit.module('GradebookHeaderMenu#curveGrades', {
  setup() {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {has_grading_periods: true},
      current_user_roles: ['admin']
    })
    this.curveGrades = GradebookHeaderMenu.prototype.curveGrades
    this.options = {assignment: {inClosedGradingPeriod: false}}
    this.spy($, 'flashError')
    this.dialogStub = this.stub(CurveGradesDialog.prototype, 'show')
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('calls the CurveGradesDialog when isAdmin is true and assignment has no due date in a closed grading period', function() {
  this.curveGrades(this.options)
  ok(this.dialogStub.called)
})

test('calls the CurveGradesDialog when isAdmin is true and assignment does have a due date in a closed grading period', function() {
  this.options.assignment.inClosedGradingPeriod = true
  this.curveGrades(this.options)
  ok(this.dialogStub.called)
})

test('calls the CurveGradesDialog when isAdmin is false and assignment has no due date in a closed grading period', function() {
  ENV.current_user_roles = []
  this.curveGrades(this.options)
  ok(this.dialogStub.called)
})

test('calls flashError when isAdmin is false and assignment does have a due date in a closed grading period', function() {
  ENV.current_user_roles = []
  this.options.assignment.inClosedGradingPeriod = true
  this.curveGrades(this.options)
  notOk(this.dialogStub.called)
  ok($.flashError.called)
})
