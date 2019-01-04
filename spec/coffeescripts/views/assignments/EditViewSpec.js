/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import React from 'react'
import _ from 'underscore'
import SectionCollection from 'compiled/collections/SectionCollection'
import Assignment from 'compiled/models/Assignment'
import DueDateList from 'compiled/models/DueDateList'
import Section from 'compiled/models/Section'
import AssignmentGroupSelector from 'compiled/views/assignments/AssignmentGroupSelector'
import DueDateOverrideView from 'compiled/views/assignments/DueDateOverride'
import EditView from 'compiled/views/assignments/EditView'
import GradingTypeSelector from 'compiled/views/assignments/GradingTypeSelector'
import GroupCategorySelector from 'compiled/views/assignments/GroupCategorySelector'
import PeerReviewsSelector from 'compiled/views/assignments/PeerReviewsSelector'
import fakeENV from 'helpers/fakeENV'
import userSettings from 'compiled/userSettings'
import assertions from 'helpers/assertions'
import tinymce from 'compiled/editor/stocktiny'
import 'helpers/jquery.simulate'

const s_params = 'some super secure params'
const fixtures = document.getElementById('fixtures')

const nameLengthHelper = function(
  view,
  length,
  maxNameLengthRequiredForAccount,
  maxNameLength,
  postToSis,
  gradingType
) {
  const name = 'a'.repeat(length)
  ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
  ENV.MAX_NAME_LENGTH = maxNameLength
  return view.validateBeforeSave({name, post_to_sis: postToSis, grading_type: gradingType}, [])
}
const editView = function(assignmentOpts = {}) {
  const defaultAssignmentOpts = {
    name: 'Test Assignment',
    secure_params: s_params,
    assignment_overrides: []
  }
  assignmentOpts = {
    ...defaultAssignmentOpts,
    ...assignmentOpts
  }
  const assignment = new Assignment(assignmentOpts)

  const sectionList = new SectionCollection([Section.defaultDueDateSection()])
  const dueDateList = new DueDateList(
    assignment.get('assignment_overrides'),
    sectionList,
    assignment
  )

  const assignmentGroupSelector = new AssignmentGroupSelector({
    parentModel: assignment,
    assignmentGroups:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.ASSIGNMENT_GROUPS : undefined) || []
  })
  const gradingTypeSelector = new GradingTypeSelector({parentModel: assignment})
  const groupCategorySelector = new GroupCategorySelector({
    parentModel: assignment,
    groupCategories:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.GROUP_CATEGORIES : undefined) || [],
    inClosedGradingPeriod: assignment.inClosedGradingPeriod()
  })
  const peerReviewsSelector = new PeerReviewsSelector({parentModel: assignment})
  const app = new EditView({
    model: assignment,
    assignmentGroupSelector,
    gradingTypeSelector,
    groupCategorySelector,
    peerReviewsSelector,
    views: {
      'js-assignment-overrides': new DueDateOverrideView({
        model: dueDateList,
        views: {}
      })
    }
  })

  return app.render()
}

function checkCheckbox(id) {
  document.getElementById(id).checked = true
}

function disableCheckbox(id) {
  document.getElementById(id).disabled = true
}

QUnit.module('EditView', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    // Sometimes TinyMCE has stuff on the dom that causes issues, likely from things that
    // don't clean up properly, we make sure that these run in a clean tiny state each time
    tinymce.remove()
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    tinymce.remove() // Make sure we clean stuff up
    $('.ui-dialog').remove()
    $('ul[id^=ui-id-]').remove()
    $('.form-dialog').remove()
    document.getElementById('fixtures').innerHTML = ''
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('should be accessible', function(assert) {
  const view = this.editView()
  const done = assert.async()
  assertions.isAccessible(view, done, {a11yReport: true})
})

test('renders', function() {
  const view = this.editView()
  equal(view.$('#assignment_name').val(), 'Test Assignment')
})

test('rejects missing group set for group assignment', function() {
  const view = this.editView()
  const data = {group_category_id: 'blank'}
  const errors = view.validateBeforeSave(data, [])
  equal(errors.newGroupCategory[0].message, 'Please create a group set')
})

test('rejects a letter for points_possible', function() {
  const view = this.editView()
  const data = {points_possible: 'a'}
  const errors = view.validateBeforeSave(data, [])
  equal(errors.points_possible[0].message, 'Points possible must be a number')
})

test('validates presence of a final grader', function() {
  const view = this.editView()
  sinon.spy(view, 'validateFinalGrader')
  view.validateBeforeSave({}, [])
  strictEqual(view.validateFinalGrader.callCount, 1)
  view.validateFinalGrader.restore()
})

test('validates grader count', function() {
  const view = this.editView()
  sinon.spy(view, 'validateGraderCount')
  view.validateBeforeSave({}, [])
  strictEqual(view.validateGraderCount.callCount, 1)
  view.validateGraderCount.restore()
})

test('does not allow group assignment for large rosters', function() {
  ENV.IS_LARGE_ROSTER = true
  const view = this.editView()
  equal(view.$('#group_category_selector').length, 0)
})

test('does not allow group assignment for anonymously graded assignments', () => {
  ENV.ANONYMOUS_GRADING_ENABLED = true
  const view = editView({anonymous_grading: true})
  view.$el.appendTo($('#fixtures'))
  view.afterRender() // call this because it's called before everything is rendered in the specs
  const hasGroupCategoryCheckbox = view.$el.find('input#has_group_category')

  strictEqual(hasGroupCategoryCheckbox.prop('disabled'), true)
})

test('does not allow peer review for large rosters', function() {
  ENV.IS_LARGE_ROSTER = true
  const view = this.editView()
  equal(view.$('#assignment_peer_reviews_fields').length, 0)
})

test('adds and removes student group', function() {
  ENV.GROUP_CATEGORIES = [{id: 1, name: 'fun group'}]
  ENV.ASSIGNMENT_GROUPS = [{id: 1, name: 'assignment group 1'}]
  const view = this.editView()
  equal(view.assignment.toView().groupCategoryId, null)
})

test('does not allow point value of -1 or less if grading type is letter', function() {
  const view = this.editView()
  const data = {points_possible: '-1', grading_type: 'letter_grade'}
  const errors = view._validatePointsRequired(data, [])
  equal(
    errors.points_possible[0].message,
    'Points possible must be 0 or more for selected grading type'
  )
})

test('requires name to save assignment', function() {
  const view = this.editView()
  const data = {name: ''}
  const errors = view.validateBeforeSave(data, [])
  ok(errors.name)
  equal(errors.name.length, 1)
  equal(errors.name[0].message, 'Name is required!')
})

test('has an error when a name has 257 chars', function() {
  const view = this.editView()
  const errors = nameLengthHelper(view, 257, false, 30, '1', 'points')
  ok(errors.name)
  equal(errors.name.length, 1)
  equal(errors.name[0].message, 'Name is too long, must be under 257 characters')
})

test('allows assignment to save when a name has 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', function() {
  const view = this.editView()
  const errors = nameLengthHelper(view, 256, false, 30, '1', 'points')
  equal(errors.length, 0)
})

test('allows assignment to save when a name has 15 chars, MAX_NAME_LENGTH is 10 and is required, post_to_sis is true and grading_type is not_graded', function() {
  const view = this.editView()
  const errors = nameLengthHelper(view, 15, true, 10, '1', 'not_graded')
  equal(errors.length, 0)
})

test('has an error when a name has 11 chars, MAX_NAME_LENGTH is 10 and required and post_to_sis is true', function() {
  const view = this.editView()
  const errors = nameLengthHelper(view, 11, true, 10, '1', 'points')
  ok(errors.name)
  equal(errors.name.length, 1)
  equal(errors.name[0].message, 'Name is too long, must be under 11 characters')
})

test('allows assignment to save when name has 11 chars, MAX_NAME_LENGTH is 10 and required, but post_to_sis is false', function() {
  const view = this.editView()
  const errors = nameLengthHelper(view, 11, true, 10, '0', 'points')
  equal(errors.length, 0)
})

test('allows assignment to save when name has 10 chars, MAX_NAME_LENGTH is 10 and required, and post_to_sis is true', function() {
  const view = this.editView()
  const errors = nameLengthHelper(view, 10, true, 10, '1', 'points')
  equal(errors.length, 0)
})

test("don't validate name if it is frozen", function() {
  const view = this.editView()
  view.model.set('frozen_attributes', ['title'])

  const errors = view.validateBeforeSave({}, [])
  notOk(errors.name)
})

test('renders a hidden secure_params field', function() {
  const view = this.editView()
  const secure_params = view.$('#secure_params')

  equal(secure_params.attr('type'), 'hidden')
  equal(secure_params.val(), s_params)
})

test('does show error message on assignment point change with submissions', function() {
  const view = this.editView({has_submitted_submissions: true})
  view.$el.appendTo($('#fixtures'))
  notOk(view.$el.find('#point_change_warning:visible').attr('aria-expanded'))
  view.$el.find('#assignment_points_possible').val(1)
  view.$el.find('#assignment_points_possible').trigger('change')
  ok(view.$el.find('#point_change_warning:visible').attr('aria-expanded'))
  view.$el.find('#assignment_points_possible').val(0)
  view.$el.find('#assignment_points_possible').trigger('change')
  notOk(view.$el.find('#point_change_warning:visible').attr('aria-expanded'))
})

test('does show error message on assignment point change without submissions', function() {
  const view = this.editView({has_submitted_submissions: false})
  view.$el.appendTo($('#fixtures'))
  notOk(view.$el.find('#point_change_warning:visible').attr('aria-expanded'))
  view.$el.find('#assignment_points_possible').val(1)
  view.$el.find('#assignment_points_possible').trigger('change')
  notOk(view.$el.find('#point_change_warning:visible').attr('aria-expanded'))
})

test('does not allow point value of "" if grading type is letter', function() {
  const view = this.editView()
  const data = {points_possible: '', grading_type: 'letter_grade'}
  const errors = view._validatePointsRequired(data, [])
  equal(
    errors.points_possible[0].message,
    'Points possible must be 0 or more for selected grading type'
  )

  //removes student group
  view.$('#has_group_category').click()
  equal(view.getFormData().groupCategoryId, null)
})

test('does not allow blank external tool url', function() {
  const view = this.editView()
  const data = {submission_type: 'external_tool'}
  const errors = view._validateExternalTool(data, [])
  equal(
    errors['external_tool_tag_attributes[url]'][0].message,
    'External Tool URL cannot be left blank'
  )
})

test('does not validate allowed extensions if file uploads is not a submission type', function() {
  const view = this.editView()
  const data = {submission_types: ['online_url'], allowed_extensions: []}
  const errors = view._validateAllowedExtensions(data, [])
  equal(errors.allowed_extensions, null)
})

test('removes group_category_id if an external tool is selected', function() {
  const view = this.editView()
  let data = {
    submission_type: 'external_tool',
    group_category_id: '1'
  }
  data = view._unsetGroupsIfExternalTool(data)
  equal(data.group_category_id, null)
})

test('renders escaped angle brackets properly', function() {
  const desc = '<p>&lt;E&gt;</p>'
  const view = this.editView({description: '<p>&lt;E&gt;</p>'})
  equal(view.$description.val().match(desc), desc)
})

test('routes to discussion details normally', function() {
  const view = this.editView({html_url: 'http://foo'})
  equal(view.locationAfterSave({}), 'http://foo')
})

test('routes to return_to', function() {
  const view = this.editView({html_url: 'http://foo'})
  equal(view.locationAfterSave({return_to: 'http://bar'}), 'http://bar')
})

test('does not route to return_to with javascript protocol', function() {
  const view = this.editView({html_url: 'http://foo'})
  // eslint-disable-next-line no-script-url
  equal(view.locationAfterSave({return_to: 'javascript:alert(1)'}), 'http://foo')
})

test('cancels to env normally', function() {
  ENV.CANCEL_TO = 'http://foo'
  const view = this.editView()
  equal(view.locationAfterCancel({}), 'http://foo')
})

test('cancels to return_to', function() {
  ENV.CANCEL_TO = 'http://foo'
  const view = this.editView()
  equal(view.locationAfterCancel({return_to: 'http://bar'}), 'http://bar')
})

test('does not cancel to return_to with javascript protocol', function() {
  ENV.CANCEL_TO = 'http://foo'
  const view = this.editView()
  // eslint-disable-next-line no-script-url
  equal(view.locationAfterCancel({return_to: 'javascript:alert(1)'}), 'http://foo')
})

test('disables fields when inClosedGradingPeriod', function() {
  const view = this.editView({in_closed_grading_period: true})
  view.$el.appendTo($('#fixtures'))

  ok(view.$el.find('#assignment_name').attr('readonly'))
  ok(view.$el.find('#assignment_points_possible').attr('readonly'))
  ok(view.$el.find('#assignment_group_id').attr('readonly'))
  equal(view.$el.find('#assignment_group_id').attr('aria-readonly'), 'true')
  ok(view.$el.find('#assignment_grading_type').attr('readonly'))
  equal(view.$el.find('input[name="grading_type"]').attr('type'), 'hidden')
  ok(view.$el.find('#has_group_category').attr('readonly'))
  equal(view.$el.find('#has_group_category').attr('aria-readonly'), 'true')
})

test('disables grading type field when frozen', function() {
  const view = this.editView({frozen_attributes: ['grading_type']})
  view.$el.appendTo($('#fixtures'))

  ok(view.$el.find('#assignment_grading_type').attr('readonly'))
  equal(view.$el.find('input[name="grading_type"]').attr('type'), 'hidden')
})

test('does not disable post to sis when inClosedGradingPeriod', function() {
  ENV.POST_TO_SIS = true
  const view = this.editView({in_closed_grading_period: true})
  view.$el.appendTo($('#fixtures'))
  notOk(view.$el.find('#assignment_post_to_sis').attr('disabled'))
})

test('disableCheckbox is called for a disabled checkbox', function() {
  const view = this.editView({in_closed_grading_period: true})
  view.$el.appendTo($('#fixtures'))
  $('<input type="checkbox" id="checkbox_fixture"/>').appendTo($(view.$el))

  // because we're stubbing so late we must call disableFields() again
  const disableCheckboxStub = sandbox.stub(view, 'disableCheckbox')
  view.disableFields()
  equal(disableCheckboxStub.called, true)
})

test('ignoreClickHandler is called for a disabled radio', function() {
  const view = this.editView({in_closed_grading_period: true})
  view.$el.appendTo($('#fixtures'))

  $('<input type="radio" id="fixture_radio"/>').appendTo($(view.$el))

  // because we're stubbing so late we must call disableFields() again
  const ignoreClickHandlerStub = sandbox.stub(view, 'ignoreClickHandler')
  view.disableFields()

  view.$el.find('#fixture_radio').click()
  equal(ignoreClickHandlerStub.calledOnce, true)
})

test('lockSelectValueHandler is called for a disabled select', function() {
  const view = this.editView({in_closed_grading_period: true})
  view.$el.html('')
  $('<select id="select_fixture"><option selected>1</option></option>2</option></select>').appendTo(
    $(view.$el)
  )
  view.$el.appendTo($('#fixtures'))

  // because we're stubbing so late we must call disableFields() again
  const lockSelectValueHandlerStub = sandbox.stub(view, 'lockSelectValueHandler')
  view.disableFields()
  equal(lockSelectValueHandlerStub.calledOnce, true)
})

test('lockSelectValueHandler freezes selected value', function() {
  const view = this.editView({in_closed_grading_period: true})
  view.$el.html('')
  $('<select id="select_fixture"><option selected>1</option></option>2</option></select>').appendTo(
    $(view.$el)
  )
  view.$el.appendTo($('#fixtures'))

  const selectedValue = view.$el.find('#fixture_select').val()
  view.$el
    .find('#fixture_select')
    .val(2)
    .trigger('change')
  equal(view.$el.find('#fixture_select').val(), selectedValue)
})

test('fields are enabled when not inClosedGradingPeriod', function() {
  const view = this.editView()
  view.$el.appendTo($('#fixtures'))

  notOk(view.$el.find('#assignment_name').attr('readonly'))
  notOk(view.$el.find('#assignment_points_possible').attr('readonly'))
  notOk(view.$el.find('#assignment_group_id').attr('readonly'))
  notOk(view.$el.find('#assignment_group_id').attr('aria-readonly'))
  notOk(view.$el.find('#assignment_grading_type').attr('readonly'))
  notOk(view.$el.find('#assignment_grading_type').attr('aria-readonly'))
  notOk(view.$el.find('#has_group_category').attr('readonly'))
  notOk(view.$el.find('#has_group_category').attr('aria-readonly'))
})

test('rounds points_possible', function() {
  const view = this.editView()
  view.$assignmentPointsPossible.val('1.234')
  const data = view.getFormData()
  equal(data.points_possible, 1.23)
})

test('sets seconds of due_at to 59 if the new minute value is 59', function() {
  const view = this.editView({due_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:58:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.due_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))
  strictEqual(view.getFormData().due_at, '2000-08-28T11:59:59.000Z')
})

test('sets seconds of due_at to 00 if the new minute value is not 59', function() {
  const view = this.editView({due_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.due_at = $.unfudgeDateForProfileTimezone(new Date('2000-09-28T11:58:23'))
  strictEqual(view.getFormData().due_at, '2000-09-28T11:58:00.000Z')
})

// The UI doesn't allow editing the seconds value and always returns 00. If
// the seconds value was set to something different prior to the update, keep
// that value.
test('keeps original due_at seconds if only the seconds value has changed', function() {
  const view = this.editView({due_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-29T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.due_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-29T11:59:59'))
  strictEqual(view.getFormData().due_at, '2000-08-29T11:59:23.000Z')
})

test('keeps original due_at seconds if the date has not changed', function() {
  const view = this.editView({due_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.due_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))
  strictEqual(view.getFormData().due_at, '2000-08-28T11:59:23.000Z')
})

test('sets seconds of unlock_at to 59 if the new minute value is 59', function() {
  const view = this.editView({unlock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:58:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.unlock_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))
  strictEqual(view.getFormData().unlock_at, '2000-08-28T11:59:59.000Z')
})

test('sets seconds of unlock_at to 00 if the new minute value is not 59', function() {
  const view = this.editView({unlock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.unlock_at = $.unfudgeDateForProfileTimezone(new Date('2000-09-28T11:58:23'))
  strictEqual(view.getFormData().unlock_at, '2000-09-28T11:58:00.000Z')
})

// The UI doesn't allow editing the seconds value and always returns 00. If
// the seconds value was set to something different prior to the update, keep
// that value.
test('keeps original unlock_at seconds if only the seconds value has changed', function() {
  const view = this.editView({unlock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-29T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.unlock_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-29T11:59:59'))
  strictEqual(view.getFormData().unlock_at, '2000-08-29T11:59:23.000Z')
})

test('keeps original unlock_at seconds if the date has not changed', function() {
  const view = this.editView({unlock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.unlock_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))
  strictEqual(view.getFormData().unlock_at, '2000-08-28T11:59:23.000Z')
})

test('sets seconds of lock_at to 59 if the new minute value is 59', function() {
  const view = this.editView({lock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:58:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.lock_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))
  strictEqual(view.getFormData().lock_at, '2000-08-28T11:59:59.000Z')
})

test('sets seconds of lock_at to 00 if the new minute value is not 59', function() {
  const view = this.editView({lock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.lock_at = $.unfudgeDateForProfileTimezone(new Date('2000-09-28T11:58:23'))
  strictEqual(view.getFormData().lock_at, '2000-09-28T11:58:00.000Z')
})

// The UI doesn't allow editing the seconds value and always returns 00. If
// the seconds value was set to something different prior to the update, keep
// that value.
test('keeps original lock_at seconds if only the seconds value has changed', function() {
  const view = this.editView({lock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-29T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.lock_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-29T11:59:59'))
  strictEqual(view.getFormData().lock_at, '2000-08-29T11:59:23.000Z')
})

test('keeps original lock_at seconds if the date has not changed', function() {
  const view = this.editView({lock_at: $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))})
  const override = view.assignment.attributes.assignment_overrides.models[0]
  override.attributes.lock_at = $.unfudgeDateForProfileTimezone(new Date('2000-08-28T11:59:23'))
  strictEqual(view.getFormData().lock_at, '2000-08-28T11:59:23.000Z')
})

QUnit.module('EditView: handleGroupCategoryChange', {
  setup() {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <input type="checkbox" id="has_group_category" >
      <input type="checkbox" id="assignment_anonymous_grading">
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('unchecks the group category checkbox if the anonymous grading checkbox is checked', function() {
  const view = this.editView()
  checkCheckbox('assignment_anonymous_grading')
  checkCheckbox('has_group_category')
  view.handleGroupCategoryChange()
  const groupCategoryCheckbox = document.getElementById('has_group_category')
  strictEqual(groupCategoryCheckbox.checked, false)
})

test('disables the anonymous grading checkbox if the group category checkbox is checked', function() {
  const view = this.editView()
  checkCheckbox('has_group_category')
  view.handleGroupCategoryChange()
  const anonymousGradingCheckbox = document.getElementById('assignment_anonymous_grading')
  strictEqual(anonymousGradingCheckbox.disabled, true)
})

test('enables the anonymous grading checkbox if the group category checkbox is unchecked', function() {
  const view = this.editView()
  disableCheckbox('assignment_anonymous_grading')
  view.handleGroupCategoryChange()
  const anonymousGradingCheckbox = document.getElementById('assignment_anonymous_grading')
  strictEqual(anonymousGradingCheckbox.disabled, false)
})

test('calls togglePeerReviewsAndGroupCategoryEnabled', function() {
  const view = this.editView()
  sinon.spy(view, 'togglePeerReviewsAndGroupCategoryEnabled')
  view.handleGroupCategoryChange()
  ok(view.togglePeerReviewsAndGroupCategoryEnabled.calledOnce)
  view.togglePeerReviewsAndGroupCategoryEnabled.restore()
})

QUnit.module('#handleAnonymousGradingChange', (hooks) => {
  let server
  let view

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <input type="checkbox" id="has_group_category" >
      <input type="checkbox" id="assignment_anonymous_grading">
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('unchecks the anonymous grading checkbox when the group category checkbox is checked', () => {
    checkCheckbox('has_group_category')
    checkCheckbox('assignment_anonymous_grading')
    view.handleAnonymousGradingChange()
    const anonymousGradingCheckbox = document.getElementById('assignment_anonymous_grading')
    strictEqual(anonymousGradingCheckbox.checked, false)
  })

  test('disables the group category box if the anonymous grading checkbox is checked', () => {
    checkCheckbox('assignment_anonymous_grading')
    view.handleAnonymousGradingChange()
    const groupCategoryCheckbox = document.getElementById('has_group_category')
    strictEqual(groupCategoryCheckbox.disabled, true)
  })

  test('disables the group category box if graders anonymous to graders is true', () => {
    view.assignment.gradersAnonymousToGraders(true)
    view.handleAnonymousGradingChange()
    const groupCategoryCheckbox = document.getElementById('has_group_category')
    strictEqual(groupCategoryCheckbox.disabled, true)
  })

  test('enables the group category box if the assignment is not moderated', () => {
    disableCheckbox('has_group_category')
    view.handleAnonymousGradingChange()
    const groupCategoryCheckbox = document.getElementById('has_group_category')
    strictEqual(groupCategoryCheckbox.disabled, false)
  })

  test('leaves the group category box disabled if the assignment is moderated', () => {
    view.assignment.moderatedGrading(true)
    disableCheckbox('has_group_category')
    view.handleAnonymousGradingChange()
    const groupCategoryCheckbox = document.getElementById('has_group_category')
    strictEqual(groupCategoryCheckbox.disabled, true)
  })

  test('leaves the group category box disabled if the assignment has submissions', () => {
    disableCheckbox('has_group_category')
    view.model.set('has_submitted_submissions', true)
    view.handleAnonymousGradingChange()
    const groupCategoryCheckbox = document.getElementById('has_group_category')
    strictEqual(groupCategoryCheckbox.disabled, true)
  })
})

QUnit.module('#togglePeerReviewsAndGroupCategoryEnabled', (hooks) => {
  let server
  let view

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <input type="checkbox" id="has_group_category" >
      <input type="checkbox" id="assignment_peer_reviews">
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('disables the peer review checkbox if the assignment is moderated', () => {
    view.assignment.moderatedGrading(true)
    view.togglePeerReviewsAndGroupCategoryEnabled()
    const peerReviewsCheckbox = document.getElementById('assignment_peer_reviews')
    strictEqual(peerReviewsCheckbox.disabled, true)
  })

  test('disables the group category checkbox if the assignment is moderated', () => {
    view.assignment.moderatedGrading(true)
    view.togglePeerReviewsAndGroupCategoryEnabled()
    const groupCategoryCheckbox = document.getElementById('has_group_category')
    strictEqual(groupCategoryCheckbox.disabled, true)
  })

  test('enables the peer review checkbox if the assignment is not moderated', () => {
    disableCheckbox('assignment_peer_reviews')
    view.togglePeerReviewsAndGroupCategoryEnabled()
    const peerReviewsCheckbox = document.getElementById('assignment_peer_reviews')
    strictEqual(peerReviewsCheckbox.disabled, false)
  })

  test('enables the group category checkbox if the assignment is not moderated', () => {
    disableCheckbox('has_group_category')
    view.togglePeerReviewsAndGroupCategoryEnabled()
    const peerReviewsCheckbox = document.getElementById('has_group_category')
    strictEqual(peerReviewsCheckbox.disabled, false)
  })

  test('renders the moderated grading form field group', () => {
    sinon.stub(view, 'renderModeratedGradingFormFieldGroup')
    view.togglePeerReviewsAndGroupCategoryEnabled()
    strictEqual(view.renderModeratedGradingFormFieldGroup.callCount, 1)
    view.renderModeratedGradingFormFieldGroup.restore()
  })
})

QUnit.module('EditView: group category inClosedGradingPeriod', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('lock down group category after students submit', function() {
  let view = this.editView({has_submitted_submissions: true})
  ok(view.$('.group_category_locked_explanation').length)
  ok(view.$('#has_group_category').prop('disabled'))
  ok(view.$('#assignment_group_category_id').prop('disabled'))
  notOk(view.$('[type=checkbox][name=grade_group_students_individually]').prop('disabled'))

  view = this.editView({has_submitted_submissions: false})
  equal(view.$('.group_category_locked_explanation').length, 0)
  notOk(view.$('#has_group_category').prop('disabled'))
  notOk(view.$('#assignment_group_category_id').prop('disabled'))
  notOk(view.$('[type=checkbox][name=grade_group_students_individually]').prop('disabled'))
})

QUnit.module('EditView: enableCheckbox', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
  },

  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },

  editView() {
    return editView.apply(this, arguments)
  }
})

test('enables checkbox', function() {
  const view = this.editView()
  sandbox.stub(view.$('#assignment_peer_reviews'), 'parent').returns(
    view.$('#assignment_peer_reviews')
  )

  view.$('#assignment_peer_reviews').prop('disabled', true)
  view.enableCheckbox(view.$('#assignment_peer_reviews'))
  notOk(view.$('#assignment_peer_reviews').prop('disabled'))
})

test('does nothing if assignment is in closed grading period', function() {
  const view = this.editView()
  sandbox.stub(view.assignment, 'inClosedGradingPeriod').returns(true)

  view.$('#assignment_peer_reviews').prop('disabled', true)
  view.enableCheckbox(view.$('#assignment_peer_reviews'))
  ok(view.$('#assignment_peer_reviews').prop('disabled'))
})

QUnit.module('EditView: setDefaultsIfNew', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('returns values from localstorage', function() {
  sandbox.stub(userSettings, 'contextGet').returns({submission_types: ['foo']})
  const view = this.editView()
  view.setDefaultsIfNew()
  deepEqual(view.assignment.get('submission_types'), ['foo'])
})

test('returns string booleans as integers', function() {
  sandbox.stub(userSettings, 'contextGet').returns({peer_reviews: '1'})
  const view = this.editView()
  view.setDefaultsIfNew()
  equal(view.assignment.get('peer_reviews'), 1)
})

test('doesnt overwrite existing assignment settings', function() {
  sandbox.stub(userSettings, 'contextGet').returns({assignment_group_id: 99})
  const view = this.editView()
  view.assignment.set('assignment_group_id', 22)
  view.setDefaultsIfNew()
  equal(view.assignment.get('assignment_group_id'), 22)
})

test('sets assignment submission type to online if not already set', function() {
  const view = this.editView()
  view.setDefaultsIfNew()
  deepEqual(view.assignment.get('submission_types'), ['online'])
})

test('doesnt overwrite assignment submission type', function() {
  const view = this.editView()
  view.assignment.set('submission_types', ['external_tool'])
  view.setDefaultsIfNew()
  deepEqual(view.assignment.get('submission_types'), ['external_tool'])
})

test('will overwrite empty arrays', function() {
  sandbox.stub(userSettings, 'contextGet').returns({submission_types: ['foo']})
  const view = this.editView()
  view.assignment.set('submission_types', [])
  view.setDefaultsIfNew()
  deepEqual(view.assignment.get('submission_types'), ['foo'])
})

QUnit.module('EditView: setDefaultsIfNew: no localStorage', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    sandbox.stub(userSettings, 'contextGet').returns(null)
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('submission_type is online if no cache', function() {
  const view = this.editView()
  view.setDefaultsIfNew()
  deepEqual(view.assignment.get('submission_types'), ['online'])
})

QUnit.module('EditView: cacheAssignmentSettings', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('saves valid attributes to localstorage', function() {
  const view = this.editView()
  sandbox.stub(view, 'getFormData').returns({points_possible: 34})
  userSettings.contextSet('new_assignment_settings', {})
  view.cacheAssignmentSettings()
  equal(34, userSettings.contextGet('new_assignment_settings').points_possible)
})

test('rejects invalid attributes when caching', function() {
  const view = this.editView()
  sandbox.stub(view, 'getFormData').returns({invalid_attribute_example: 30})
  userSettings.contextSet('new_assignment_settings', {})
  view.cacheAssignmentSettings()
  equal(null, userSettings.contextGet('new_assignment_settings').invalid_attribute_example)
})

QUnit.module('EditView: Conditional Release', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      CONDITIONAL_RELEASE_ENV: {assignment: {id: 1}, jwt: 'foo'},
      CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    $(document).on('submit', () => false)
    this.server = sinon.fakeServer.create()
  },

  teardown() {
    this.server.restore()
    fakeENV.teardown()
    $(document).off('submit')
    document.getElementById('fixtures').innerHTML = ''
  },

  editView() {
    return editView.apply(this, arguments)
  }
})

test('attaches conditional release editor', function() {
  const view = this.editView()
  equal(1, view.$conditionalReleaseTarget.children().size())
})

test('calls update on first switch', function() {
  const view = this.editView()
  const stub = sandbox.stub(view.conditionalReleaseEditor, 'updateAssignment')
  view.updateConditionalRelease()
  ok(stub.calledOnce)
})

test('calls update when modified once', function() {
  const view = this.editView()
  const stub = sandbox.stub(view.conditionalReleaseEditor, 'updateAssignment')
  view.onChange()
  view.updateConditionalRelease()
  ok(stub.calledOnce)
})

test('does not call update when not modified', function() {
  const view = this.editView()
  const stub = sandbox.stub(view.conditionalReleaseEditor, 'updateAssignment')
  view.updateConditionalRelease()
  stub.reset()
  view.updateConditionalRelease()
  notOk(stub.called)
})

test('validates conditional release', function() {
  const view = this.editView()
  ENV.ASSIGNMENT = view.assignment
  const stub = sandbox.stub(view.conditionalReleaseEditor, 'validateBeforeSave').returns('foo')
  const errors = view.validateBeforeSave(view.getFormData(), {})
  ok(errors.conditional_release === 'foo')
})

test('calls save in conditional release', function(assert) {
  const resolved = assert.async()
  const view = this.editView()
  const superPromise = $.Deferred()
    .resolve()
    .promise()
  const crPromise = $.Deferred()
    .resolve()
    .promise()
  const mockSuper = sinon.mock(EditView.__super__)
  mockSuper.expects('saveFormData').returns(superPromise)
  const stub = sandbox.stub(view.conditionalReleaseEditor, 'save').returns(crPromise)
  const finalPromise = view.saveFormData()
  return finalPromise.then(() => {
    mockSuper.verify()
    ok(stub.calledOnce)
    return resolved()
  })
})

test('focuses in conditional release editor if conditional save validation fails', function() {
  const view = this.editView()
  const focusOnError = sandbox.stub(view.conditionalReleaseEditor, 'focusOnError')
  view.showErrors({conditional_release: {type: 'foo'}})
  ok(focusOnError.called)
})

QUnit.module('Editview: Intra-Group Peer Review toggle', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('only appears for group assignments', function() {
  sandbox.stub(userSettings, 'contextGet').returns({
    peer_reviews: '1',
    group_category_id: 1,
    automatic_peer_reviews: '1'
  })
  const view = this.editView()
  view.$el.appendTo($('#fixtures'))
  ok(view.$('#intra_group_peer_reviews').is(':visible'))
})

test('does not appear when reviews are being assigned manually', function() {
  sandbox.stub(userSettings, 'contextGet').returns({
    peer_reviews: '1',
    group_category_id: 1
  })
  const view = this.editView()
  view.$el.appendTo($('#fixtures'))
  notOk(view.$('#intra_group_peer_reviews').is(':visible'))
})

test('toggle does not appear when there is no group', function() {
  sandbox.stub(userSettings, 'contextGet').returns({peer_reviews: '1'})
  const view = this.editView()
  view.$el.appendTo($('#fixtures'))
  notOk(view.$('#intra_group_peer_reviews').is(':visible'))
})

QUnit.module('EditView: Assignment Configuration Tools', {
  setup() {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      PLAGIARISM_DETECTION_PLATFORM: true,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
  },

  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  },

  editView() {
    return editView.apply(this, arguments)
  }
})

test('it attaches assignment configuration component', function() {
  const view = this.editView()
  equal(view.$similarityDetectionTools.children().size(), 1)
})

test('it is hidden if submission type is not online with a file upload', function() {
  const view = this.editView()
  view.$el.appendTo($('#fixtures'))
  equal(view.$('#similarity_detection_tools').css('display'), 'none')

  view.$('#assignment_submission_type').val('on_paper')
  view.handleSubmissionTypeChange()
  equal(view.$('#similarity_detection_tools').css('display'), 'none')

  view.$('#assignment_submission_type').val('external_tool')
  view.handleSubmissionTypeChange()
  equal(view.$('#similarity_detection_tools').css('display'), 'none')

  view.$('#assignment_submission_type').val('online')
  view.$('#assignment_online_upload').attr('checked', false)
  view.handleSubmissionTypeChange()
  equal(view.$('#similarity_detection_tools').css('display'), 'none')

  view.$('#assignment_submission_type').val('online')
  view.$('#assignment_online_upload').attr('checked', true)
  view.handleSubmissionTypeChange()
  equal(view.$('#similarity_detection_tools').css('display'), 'block')

  view.$('#assignment_submission_type').val('online')
  view.$('#assignment_text_entry').attr('checked', false)
  view.$('#assignment_online_upload').attr('checked', false)
  view.handleSubmissionTypeChange()
  equal(view.$('#similarity_detection_tools').css('display'), 'none')

  view.$('#assignment_submission_type').val('online')
  view.$('#assignment_text_entry').attr('checked', true)
  view.handleSubmissionTypeChange()
  equal(view.$('#similarity_detection_tools').css('display'), 'block')
})

test('it is hidden if the plagiarism_detection_platform flag is disabled', function() {
  ENV.PLAGIARISM_DETECTION_PLATFORM = false
  const view = this.editView()
  view.$('#assignment_submission_type').val('online')
  view.$('#assignment_online_upload').attr('checked', true)
  view.handleSubmissionTypeChange()
  equal(view.$('#similarity_detection_tools').css('display'), 'none')
})

QUnit.module('EditView: Assignment External Tools', {
  setup() {
    fakeENV.setup({})
    this.server = sinon.fakeServer.create()
  },

  teardown() {
    this.server.restore()
    fakeENV.teardown()
  },

  editView() {
    return editView.apply(this, arguments)
  }
})

test('it attaches assignment external tools component', function() {
  const view = this.editView()
  equal(view.$assignmentExternalTools.children().size(), 1)
})

QUnit.module('EditView: Quizzes 2', {
  setup() {
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    this.server = sinon.fakeServer.create()
    this.view = editView({
      submission_types: ['external_tool'],
      is_quiz_lti_assignment: true
    })
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    document.getElementById('fixtures').innerHTML = ''
  }
})

test('does not show the description textarea', function() {
  equal(this.view.$description.length, 0)
})

test('does not show the moderated grading checkbox', function() {
  equal(document.getElementById('assignment_moderated_grading'), null)
})

test('does not show the load in new tab checkbox', function() {
  equal(this.view.$externalToolsNewTab.length, 0)
})

QUnit.module('EditView: anonymous grading', (hooks) => {
  let server;
  hooks.beforeEach(() => {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
  });

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  });

  test('does not show the checkbox when environment is not set', () => {
    const view = editView()
    strictEqual(view.toJSON().anonymousGradingEnabled, false)
    strictEqual(view.$el.find('input#assignment_anonymous_grading').length, 0)
  })

  test('does not show the checkbox when environment set to false', () => {
    ENV.ANONYMOUS_GRADING_ENABLED = false
    const view = editView()
    strictEqual(view.toJSON().anonymousGradingEnabled, false)
    strictEqual(view.$el.find('input#assignment_anonymous_grading').length, 0)
  })

  test('shows the checkbox when environment is set to true', () => {
    ENV.ANONYMOUS_GRADING_ENABLED = true
    const view = editView()
    strictEqual(view.toJSON().anonymousGradingEnabled, true)
    strictEqual(view.$el.find('input#assignment_anonymous_grading').length, 1)
  })

  test('is disabled when group assignment is enabled', () => {
    ENV.ANONYMOUS_GRADING_ENABLED = true
    ENV.GROUP_CATEGORIES = [
      {id: '1', name: 'Group Category #1'}
    ]
    const view = editView({group_category_id: '1'})
    view.$el.appendTo($('#fixtures'))
    view.afterRender() // call this because it's called before everything is rendered in the specs
    const anonymousGradingCheckbox = view.$el.find('input#assignment_anonymous_grading')

    strictEqual(anonymousGradingCheckbox.prop('disabled'), true)
  })
})

QUnit.module('EditView: Anonymous Instructor Annotations', (hooks) => {
  let server

  function setupFakeEnv(envOptions = {}) {
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1,
      ...envOptions
    })
  }

  hooks.beforeEach(() => {
    fixtures.innerHTML = '<span data-component="ModeratedGradingFormFieldGroup"></span>'
    server = sinon.fakeServer.create()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('when environment is not set, does not enable editing the property', function() {
    setupFakeEnv()
    strictEqual(editView().$el.find('input#assignment_anonymous_instructor_annotations').length, 0)
  })

  test('when environment is set to false, does not enable editing the property', function() {
    setupFakeEnv({ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED: false})
    strictEqual(editView().$el.find('input#assignment_anonymous_instructor_annotations').length, 0)
  })

  test('when environment is set to true, enables editing the property', function() {
    setupFakeEnv({ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED: true})
    strictEqual(editView().$el.find('input#assignment_anonymous_instructor_annotations').length, 1)
  })
})

QUnit.module('EditView: Anonymous Moderated Marking', (hooks) => {
  let server

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('adds the ModeratedGradingFormFieldGroup mount point', () => {
    const view = editView()
    view.toJSON()
    strictEqual(view.$el.find('[data-component="ModeratedGradingFormFieldGroup"]').length, 1)
  })
})

QUnit.module('EditView#validateFinalGrader', (hooks) => {
  let server
  let view

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('returns no errors if moderated grading is turned off', () => {
    const errors = view.validateFinalGrader({ moderated_grading: 'off' })
    strictEqual(Object.keys(errors).length, 0)
  })

  test('returns no errors if moderated grading is turned on and there is a final grader', () => {
    const errors = view.validateFinalGrader({ moderated_grading: 'on', final_grader_id: '89' })
    strictEqual(Object.keys(errors).length, 0)
  })

  test('returns an error if moderated grading is turned on and there is no final grader', () => {
    const errors = view.validateFinalGrader({ moderated_grading: 'on', final_grader_id: '' })
    deepEqual(Object.keys(errors), ['final_grader_id'])
  })
})

QUnit.module('EditView#validateGraderCount', (hooks) => {
  let server
  let view

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('returns no errors if moderated grading is turned off', () => {
    const errors = view.validateGraderCount({ moderated_grading: 'off' })
    strictEqual(Object.keys(errors).length, 0)
  })

  test('returns no errors if moderated grading is turned on and grader count is in an acceptable range', () => {
    const errors = view.validateGraderCount({ moderated_grading: 'on', grader_count: '6' })
    strictEqual(Object.keys(errors).length, 0)
  })

  test('returns no errors if moderated grading is turned on and grader count is greater than max grader count', () => {
    const errors = view.validateGraderCount({ moderated_grading: 'on', grader_count: '8' })
    strictEqual(Object.keys(errors).length, 0)
  })

  test('returns an error if moderated grading is turned on and grader count is empty', () => {
    const errors = view.validateGraderCount({ moderated_grading: 'on', grader_count: '' })
    deepEqual(Object.keys(errors), ['grader_count'])
  })

  test('returns an error if moderated grading is turned on and grader count is 0', () => {
    const errors = view.validateGraderCount({ moderated_grading: 'on', grader_count: '0' })
    deepEqual(Object.keys(errors), ['grader_count'])
  })
})

QUnit.module('EditView#renderModeratedGradingFormFieldGroup', (suiteHooks) => {
  let view
  let server
  const availableModerators = [{ name: 'John Doe', id: '21' }, { name: 'Jane Doe', id: '89' }]

  suiteHooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <input id="assignment_peer_reviews" type="checkbox"></input>
      <input id="has_group_category" type="checkbox"></input>
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: availableModerators,
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: false,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  suiteHooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('renders the moderated grading form field group when Moderated Grading is enabled', () => {
    ENV.MODERATED_GRADING_ENABLED = true
    view.renderModeratedGradingFormFieldGroup()
    strictEqual(document.getElementsByClassName('ModeratedGrading__Container').length, 1)
  })

  test('does not render the moderated grading form field group when Moderated Grading is disabled', () => {
    view.renderModeratedGradingFormFieldGroup()
    strictEqual(document.getElementsByClassName('ModeratedGrading__Container').length, 0)
  })

  QUnit.module('props passed to the component', (hooks) => {
    hooks.beforeEach(() => {
      ENV.MODERATED_GRADING_ENABLED = true
      sinon.spy(React, 'createElement')
    })

    hooks.afterEach(() => {
      React.createElement.restore()
    })

    function props() {
      return React.createElement.getCall(0).args[1]
    }

    test('passes the final_grader_id as a prop to the component', () => {
      view.assignment.set('final_grader_id', '293')
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().finalGraderID, '293')
    })

    test('passes moderated_grading as a prop to the component', () => {
      view.assignment.set('moderated_grading', true)
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().moderatedGradingEnabled, true)
    })

    test('passes available moderators in the ENV as a prop to the component', () => {
      view.assignment.set('moderated_grading', true)
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().availableModerators, availableModerators)
    })

    test('passes max grader count in the ENV as a prop to the component', () => {
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().maxGraderCount, ENV.MODERATED_GRADING_MAX_GRADER_COUNT)
    })

    test('passes locale in the ENV as a prop to the component', () => {
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().locale, ENV.LOCALE)
    })

    test('passes HAS_GRADED_SUBMISSIONS in the ENV as a prop to the component', () => {
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().gradedSubmissionsExist, ENV.HAS_GRADED_SUBMISSIONS)
    })

    test('passes current grader count as a prop to the component', () => {
      view.assignment.set('grader_count', 4)
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().currentGraderCount, 4)
    })

    test('passes grader_comments_visible_to_graders as a prop to the component', () => {
      view.assignment.set('grader_comments_visible_to_graders', true)
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().graderCommentsVisibleToGraders, true)
    })

    test('passes grader_names_visible_to_final_grader as a prop to the component', () => {
      view.assignment.set('grader_names_visible_to_final_grader', true)
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().graderNamesVisibleToFinalGrader, true)
    })

    test('passes peer_reviews as a prop to the component', () => {
      $('#assignment_peer_reviews').prop('checked', true)
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().isPeerReviewAssignment, true)
    })

    test('passes has_group_category as a prop to the component', () => {
      $('#has_group_category').prop('checked', true)
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().isGroupAssignment, true)
    })

    test('passes handleGraderCommentsVisibleToGradersChanged as a prop to the component', () => {
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().onGraderCommentsVisibleToGradersChange, view.handleGraderCommentsVisibleToGradersChanged)
    })

    test('passes handleModeratedGradingChanged as a prop to the component', () => {
      view.renderModeratedGradingFormFieldGroup()
      strictEqual(props().onModeratedGradingChange, view.handleModeratedGradingChanged)
    })
  })
})

QUnit.module('EditView#handleModeratedGradingChanged', (hooks) => {
  let server
  let view

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <label for="assignment_graders_anonymous_to_graders" style="display: none;">
        <input id="assignment_graders_anonymous_to_graders"></input>
      </label>
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('sets the moderated grading attribute on the assignment', () => {
    view.handleModeratedGradingChanged(true)
    strictEqual(view.assignment.moderatedGrading(), true)
  })

  test('calls togglePeerReviewsAndGroupCategoryEnabled', () => {
    sinon.stub(view, 'togglePeerReviewsAndGroupCategoryEnabled')
    view.handleModeratedGradingChanged(true)
    strictEqual(view.togglePeerReviewsAndGroupCategoryEnabled.callCount, 1)
    view.togglePeerReviewsAndGroupCategoryEnabled.restore()
  })

  test('reveals the "Graders Anonymous to Graders" option when passed true and ' +
  'grader comments are visible to graders', () => {
    view.assignment.graderCommentsVisibleToGraders(true)
    view.handleModeratedGradingChanged(true)
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    const isHidden = getComputedStyle(label).getPropertyValue('display') === 'none'
    strictEqual(isHidden, false)
  })

  test('does not reveal the "Graders Anonymous to Graders" option when passed true and ' +
  'grader comments are not visible to graders', () => {
    view.handleModeratedGradingChanged(true)
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    const isHidden = getComputedStyle(label).getPropertyValue('display') === 'none'
    strictEqual(isHidden, true)
  })

  test('calls uncheckAndHideGraderAnonymousToGraders when passed false', () => {
    sinon.stub(view, 'uncheckAndHideGraderAnonymousToGraders')
    view.handleModeratedGradingChanged(false)
    strictEqual(view.uncheckAndHideGraderAnonymousToGraders.callCount, 1)
    view.uncheckAndHideGraderAnonymousToGraders.restore()
  })
})

QUnit.module('EditView#handleGraderCommentsVisibleToGradersChanged', (hooks) => {
  let server
  let view

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <label for="assignment_graders_anonymous_to_graders" style="display: none;">
        <input id="assignment_graders_anonymous_to_graders"></input>
      </label>
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('sets the graderCommentsVisibleToGraders attribute on the assignment', () => {
    view.handleGraderCommentsVisibleToGradersChanged(true)
    strictEqual(view.assignment.graderCommentsVisibleToGraders(), true)
  })

  test('reveals the "Graders Anonymous to Graders" option when passed true', () => {
    view.handleGraderCommentsVisibleToGradersChanged(true)
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    const isHidden = getComputedStyle(label).getPropertyValue('display') === 'none'
    strictEqual(isHidden, false)
  })

  test('calls uncheckAndHideGraderAnonymousToGraders when passed false', () => {
    sinon.stub(view, 'uncheckAndHideGraderAnonymousToGraders')
    view.handleGraderCommentsVisibleToGradersChanged(false)
    strictEqual(view.uncheckAndHideGraderAnonymousToGraders.callCount, 1)
    view.uncheckAndHideGraderAnonymousToGraders.restore()
  })
})

QUnit.module('EditView#uncheckAndHideGraderAnonymousToGraders', (hooks) => {
  let server
  let view

  hooks.beforeEach(() => {
    fixtures.innerHTML = `
      <span id="editor_tabs"></span>
      <span data-component="ModeratedGradingFormFieldGroup"></span>
      <label for="assignment_graders_anonymous_to_graders">
        <input id="assignment_graders_anonymous_to_graders" checked></input>
      </label>
    `
    fakeENV.setup({
      AVAILABLE_MODERATORS: [],
      current_user_roles: ['teacher'],
      HAS_GRADED_SUBMISSIONS: false,
      LOCALE: 'en',
      MODERATED_GRADING_ENABLED: true,
      MODERATED_GRADING_MAX_GRADER_COUNT: 2,
      VALID_DATE_RANGE: {},
      COURSE_ID: 1
    })
    server = sinon.fakeServer.create()
    view = editView()
  })

  hooks.afterEach(() => {
    server.restore()
    fakeENV.teardown()
    fixtures.innerHTML = ''
  })

  test('sets gradersAnonymousToGraders to false on the assignment', () => {
    view.assignment.gradersAnonymousToGraders(true)
    view.uncheckAndHideGraderAnonymousToGraders()
    strictEqual(view.assignment.gradersAnonymousToGraders(), false)
  })

  test('unchecks the "Graders anonymous to graders" checkbox', () => {
    view.uncheckAndHideGraderAnonymousToGraders()
    const checkbox = document.getElementById('assignment_graders_anonymous_to_graders')
    strictEqual(checkbox.checked, false)
  })

  test('hides the "Graders anonymous to graders" checkbox', () => {
    view.uncheckAndHideGraderAnonymousToGraders()
    const label = document.querySelector('label[for="assignment_graders_anonymous_to_graders"]')
    const isHidden = getComputedStyle(label).getPropertyValue('display') === 'none'
    strictEqual(isHidden, true)
  })
})
