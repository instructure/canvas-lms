/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {extend, defer} from 'lodash'
import SectionCollection from 'compiled/collections/SectionCollection'
import Assignment from 'compiled/models/Assignment'
import DueDateList from 'compiled/models/DueDateList'
import Section from 'compiled/models/Section'
import DiscussionTopic from 'compiled/models/DiscussionTopic'
import Announcement from 'compiled/models/Announcement'
import DueDateOverrideView from 'compiled/views/assignments/DueDateOverride'
import EditView from 'compiled/views/DiscussionTopics/EditView'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import GroupCategorySelector from 'compiled/views/assignments/GroupCategorySelector'
import fakeENV from 'helpers/fakeENV'
import assertions from 'helpers/assertions'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import 'helpers/jquery.simulate'

const editView = function(opts = {}, discussOpts = {}) {
  const modelClass = opts.isAnnouncement ? Announcement : DiscussionTopic
  if (opts.withAssignment) {
    const assignmentOpts = extend({}, opts.assignmentOpts, {
      name: 'Test Assignment',
      assignment_overrides: []
    })
    discussOpts.assignment = assignmentOpts
  }
  const discussion = new modelClass(discussOpts, {parse: true})
  const assignment = discussion.get('assignment')
  const sectionList = new SectionCollection([Section.defaultDueDateSection()])
  const dueDateList = new DueDateList(
    assignment.get('assignment_overrides'),
    sectionList,
    assignment
  )
  const app = new EditView({
    model: discussion,
    permissions: opts.permissions || {},
    views: {
      'js-assignment-overrides': new DueDateOverrideView({
        model: dueDateList,
        views: {}
      })
    },
    lockedItems: opts.lockedItems || {}
  })
  ;(app.assignmentGroupCollection = new AssignmentGroupCollection()).contextAssetString =
    ENV.context_asset_string
  return app.render()
}
const nameLengthHelper = function(
  view,
  length,
  maxNameLengthRequiredForAccount,
  maxNameLength,
  postToSis
) {
  ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
  ENV.MAX_NAME_LENGTH = maxNameLength
  ENV.IS_LARGE_ROSTER = true
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const title = 'a'.repeat(length)
  const {assignment} = view
  assignment.attributes.post_to_sis = postToSis
  return view.validateBeforeSave(
    {
      title,
      set_assignment: '1',
      assignment
    },
    []
  )
}

QUnit.module('EditView', {
  setup() {
    fakeENV.setup()
    this.server = sinon.fakeServer.create({respondImmediately: true})
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.editView(), done, {a11yReport: true})
})

test('renders', function() {
  const view = this.editView()
  ok(view)
})

test('tells RCE to manage the parent', function() {
  const lne = this.stub(RichContentEditor, 'loadNewEditor')
  const view = this.editView()
  view.loadNewEditor()
  ok(lne.firstCall.args[1].manageParent, 'manageParent flag should be set')
})

test('does not tell RCE to manage the parent of locked content', function() {
  const lne = this.stub(RichContentEditor, 'loadNewEditor')
  const view = this.editView({lockedItems: {content: true}})
  view.loadNewEditor()
  ok(lne.callCount === 0, 'RCE not called')
})

test('shows error message on assignment point change with submissions', function() {
  const view = this.editView({
    withAssignment: true,
    assignmentOpts: {has_submitted_submissions: true}
  })
  view.renderGroupCategoryOptions()
  ok(view.$el.find('#discussion_point_change_warning'), 'rendered change warning')
  view.$el.find('#discussion_topic_assignment_points_possible').val(1)
  view.$el.find('#discussion_topic_assignment_points_possible').trigger('change')
  equal(
    view.$el.find('#discussion_point_change_warning').attr('aria-expanded'),
    'true',
    'change warning aria-expanded true'
  )
  view.$el.find('#discussion_topic_assignment_points_possible').val(0)
  view.$el.find('#discussion_topic_assignment_points_possible').trigger('change')
  equal(
    view.$el.find('#discussion_point_change_warning').attr('aria-expanded'),
    'false',
    'change warning aria-expanded false'
  )
})

test('hides the published icon for announcements', function() {
  const view = this.editView({isAnnouncement: true})
  equal(view.$el.find('.published-status').length, 0)
})

test('validates the group category for non-assignment discussions', function() {
  const clock = sinon.useFakeTimers()
  const view = this.editView({permissions: {CAN_SET_GROUP: true}})
  clock.tick(1)
  const data = {group_category_id: 'blank'}
  const errors = view.validateBeforeSave(data, [])
  ok(errors.newGroupCategory[0].message)
  return clock.restore()
})

test('does not render #podcast_has_student_posts_container for non-course contexts', function() {
  const view = this.editView({
    withAssignment: true,
    permissions: {CAN_MODERATE: true}
  })
  equal(view.$el.find('#podcast_enabled').length, 1)
  equal(view.$el.find('#podcast_has_student_posts_container').length, 0)
})

test('routes to discussion details normally', function() {
  const view = this.editView({}, {html_url: 'http://foo'})
  equal(view.locationAfterSave({}), 'http://foo')
})

test('routes to return_to', function() {
  const view = this.editView({}, {html_url: 'http://foo'})
  equal(view.locationAfterSave({return_to: 'http://bar'}), 'http://bar')
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

test('shows todo checkbox', function() {
  ENV.STUDENT_PLANNER_ENABLED = true
  const view = this.editView()
  equal(view.$el.find('#allow_todo_date').length, 1)
  equal(view.$el.find('#todo_date_input')[0].style.display, 'none')
})

test('shows todo input when todo checkbox is selected', function() {
  ENV.STUDENT_PLANNER_ENABLED = true
  const view = this.editView()
  view.$el.find('#allow_todo_date').prop('checked', true)
  view.$el.find('#allow_todo_date').trigger('change')
  equal(view.$el.find('#todo_date_input')[0].style.display, 'block')
})

test('shows todo input with date when given date', function() {
  ENV.STUDENT_PLANNER_ENABLED = true
  const view = this.editView({}, {todo_date: '2017-01-03'})
  equal(view.$el.find('#allow_todo_date').prop('checked'), true)
  equal(view.$el.find('#todo_date').val(), 'Jan 3, 2017 at 12am')
})

test('does not show todo checkbox without permission', function() {
  ENV.STUDENT_PLANNER_ENABLED = false
  const view = this.editView()
  equal(view.$el.find('#allow_todo_date').length, 0)
})

test('does not show todo date elements when grading is enabled', function() {
  ENV.STUDENT_PLANNER_ENABLED = true
  const view = this.editView()
  view.$el.find('#use_for_grading').prop('checked', true)
  view.$el.find('#use_for_grading').trigger('change')
  equal(view.$el.find('#todo_options')[0].style.display, 'none')
})

test('does save todo date if allow_todo_date is checked and discussion is not graded', function() {
  ENV.STUDENT_PLANNER_ENABLED = true
  const todo_date = new Date('2017-05-25T08:00:00-0800')
  const view = this.editView()
  view.renderGroupCategoryOptions()
  view.$el.find('#allow_todo_date').prop('checked', true)
  view.$el.find('#allow_todo_date').trigger('change')
  view.$el.find('#todo_date').val(todo_date.toISOString())
  view.$el.find('#todo_date').trigger('change')
  const formData = view.getFormData()
  equal(formData.todo_date.toString(), todo_date.toString())
})

test('does not save todo date if allow_todo_date is not checked', function() {
  ENV.STUDENT_PLANNER_ENABLED = true
  const view = this.editView()
  view.$el.find('#todo_date').val('2017-01-03')
  view.$el.find('#todo_date').trigger('change')
  view.renderGroupCategoryOptions()
  const formData = view.getFormData()
  equal(formData.todo_date, null)
})

test('does not save todo date if discussion is graded', function() {
  ENV.STUDENT_PLANNER_ENABLED = true
  const view = this.editView()
  view.$el.find('#todo_date').val('2017-01-03')
  view.$el.find('#todo_date').trigger('change')
  view.$el.find('#use_for_grading').prop('checked', true)
  view.$el.find('#use_for_grading').trigger('change')
  view.renderGroupCategoryOptions()
  const formData = view.getFormData()
  equal(formData.todo_date, null)
})

QUnit.module(
  'EditView - Sections Specific',
  test('allows discussion to save when section specific has errors has no section', function() {
    ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
    ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: false}}
    const view = this.editView({withAssignment: true})
    const title = 'a'.repeat(10)
    const {assignment} = view
    assignment.attributes.post_to_sis = '1'
    const errors = view.validateBeforeSave(
      {
        title,
        set_assignment: '1',
        assignment,
        specific_sections: null
      },
      []
    )
    equal(Object.keys(errors).length, 0)
  }),
  test('allows announcement to save when section specific has a section', function() {
    ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
    ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: true}}
    const view = this.editView({withAssignment: false})
    const title = 'a'.repeat(10)
    const {assignment} = view
    assignment.attributes.post_to_sis = '1'
    const errors = view.validateBeforeSave(
      {
        title,
        specific_sections: ['fake_section']
      },
      []
    )
    equal(Object.keys(errors).length, 0)
  }),
  test('allows group announcements to be saved without a section', function() {
    ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
    ENV.CONTEXT_ID = 1
    ENV.context_asset_string = 'group_1'
    ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: true}}
    const view = this.editView({withAssignment: false})
    const title = 'a'.repeat(10)
    const {assignment} = view
    assignment.attributes.post_to_sis = '1'
    const errors = view.validateBeforeSave(
      {
        title,
        specific_sections: null
      },
      []
    )
    equal(Object.keys(errors).length, 0)
  }),
  test('require section for course announcements if enabled', function() {
    ENV.should_log = true
    ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
    ENV.CONTEXT_ID = 1
    ENV.context_asset_string = 'course_1'
    ENV.DISCUSSION_TOPIC = {ATTRIBUTES: {is_announcement: true}}
    const view = this.editView({withAssignment: false})
    const title = 'a'.repeat(10)
    const {assignment} = view
    assignment.attributes.post_to_sis = '1'
    const errors = view.validateBeforeSave(
      {
        title,
        specific_sections: null
      },
      []
    )
    equal(Object.keys(errors).length, 1)
    equal(Object.keys(errors)[0], 'specific_sections')
  })
)

QUnit.module('EditView - ConditionalRelease', {
  setup() {
    fakeENV.setup()
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    ENV.CONDITIONAL_RELEASE_ENV = {
      assignment: {id: 1},
      jwt: 'foo'
    }
    $(document).on('submit', () => false)
    this.server = sinon.fakeServer.create({respondImmediately: true})
  },
  teardown() {
    this.server.restore()
    fakeENV.teardown()
    return $(document).off('submit')
  },
  editView() {
    return editView.apply(this, arguments)
  }
})

test('does not show conditional release tab when feature not enabled', function() {
  ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
  const view = this.editView()
  equal(view.$el.find('#mastery-paths-editor').length, 0)
  equal(view.$el.find('#discussion-edit-view').hasClass('ui-tabs'), false)
})

test('shows disabled conditional release tab when feature enabled, but not assignment', function() {
  const view = this.editView()
  view.renderTabs()
  view.loadConditionalRelease()
  equal(view.$el.find('#mastery-paths-editor').length, 1)
  equal(view.$discussionEditView.hasClass('ui-tabs'), true)
  equal(view.$discussionEditView.tabs('option', 'disabled'), true)
})

test('shows enabled conditional release tab when feature enabled, and assignment', function() {
  const view = this.editView({withAssignment: true})
  view.renderTabs()
  view.loadConditionalRelease()
  equal(view.$el.find('#mastery-paths-editor').length, 1)
  equal(view.$discussionEditView.hasClass('ui-tabs'), true)
  equal(view.$discussionEditView.tabs('option', 'disabled'), false)
})

test('enables conditional release tab when changed to assignment', function() {
  const view = this.editView()
  view.loadConditionalRelease()
  view.renderTabs()
  equal(view.$discussionEditView.tabs('option', 'disabled'), true)
  view.$useForGrading.prop('checked', true)
  view.$useForGrading.trigger('change')
  equal(view.$discussionEditView.tabs('option', 'disabled'), false)
})

test('disables conditional release tab when changed from assignment', function() {
  const view = this.editView({withAssignment: true})
  view.loadConditionalRelease()
  view.renderTabs()
  equal(view.$discussionEditView.tabs('option', 'disabled'), false)
  view.$useForGrading.prop('checked', false)
  view.$useForGrading.trigger('change')
  equal(view.$discussionEditView.tabs('option', 'disabled'), true)
})

test('renders conditional release tab content', function() {
  const view = this.editView({withAssignment: true})
  view.loadConditionalRelease()
  equal(1, view.$conditionalReleaseTarget.children().size())
})

test('has an error when a title is 257 chars', function() {
  const view = this.editView({withAssignment: true})
  const errors = nameLengthHelper(view, 257, false, 30, '1')
  equal(errors.title[0].message, 'Title is too long, must be under 257 characters')
})

test('allows dicussion to save when a title is 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', function() {
  const view = this.editView({withAssignment: true})
  const errors = nameLengthHelper(view, 256, false, 30, '1')
  equal(errors.length, 0)
})

test('has an error when a title > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true', function() {
  const view = this.editView({withAssignment: true})
  const errors = nameLengthHelper(view, 40, true, 30, '1')
  equal(errors.title[0].message, 'Title is too long, must be under 31 characters')
})

test('allows discussion to save when title > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is false', function() {
  const view = this.editView({withAssignment: true})
  const errors = nameLengthHelper(view, 40, true, 30, '0')
  equal(errors.length, 0)
})

test('allows discussion to save when title < MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true', function() {
  const view = this.editView({withAssignment: true})
  const errors = nameLengthHelper(view, 30, true, 40, '1')
  equal(errors.length, 0)
})

test('conditional release editor is updated on tab change', function() {
  const view = this.editView({withAssignment: true})
  view.renderTabs()
  view.renderGroupCategoryOptions()
  view.loadConditionalRelease()
  const stub = this.stub(view.conditionalReleaseEditor, 'updateAssignment')
  view.$discussionEditView.tabs('option', 'active', 1)
  ok(stub.calledOnce)
  stub.reset()
  view.$discussionEditView.tabs('option', 'active', 0)
  view.onChange()
  view.$discussionEditView.tabs('option', 'active', 1)
  ok(stub.calledOnce)
})

test('validates conditional release', function(assert) {
  const resolved = assert.async()
  const view = this.editView({withAssignment: true})
  return defer(() => {
    const stub = this.stub(view.conditionalReleaseEditor, 'validateBeforeSave').returns('foo')
    const errors = view.validateBeforeSave(view.getFormData(), {})
    ok(errors.conditional_release === 'foo')
    return resolved()
  })
})

test('calls save in conditional release', function(assert) {
  const resolved = assert.async()
  const view = this.editView({withAssignment: true})
  return defer(() => {
    const superPromise = $.Deferred()
      .resolve({})
      .promise()
    const crPromise = $.Deferred()
      .resolve({})
      .promise()
    const mockSuper = sinon.mock(EditView.__super__)
    mockSuper.expects('saveFormData').returns(superPromise)
    const stub = this.stub(view.conditionalReleaseEditor, 'save').returns(crPromise)
    const finalPromise = view.saveFormData()
    return finalPromise.then(() => {
      mockSuper.verify()
      ok(stub.calledOnce)
      return resolved()
    })
  })
})

test('does not call conditional release save for an announcement', function(assert) {
  const resolved = assert.async()
  const view = this.editView({isAnnouncement: true})
  return defer(() => {
    const superPromise = $.Deferred()
      .resolve({})
      .promise()
    const mockSuper = sinon.mock(EditView.__super__)
    mockSuper.expects('saveFormData').returns(superPromise)
    const savePromise = view.saveFormData()
    return savePromise.then(() => {
      mockSuper.verify()
      notOk(view.conditionalReleaseEditor)
      return resolved()
    })
  })
})

test('switches to conditional tab if save error contains conditional release error', function(assert) {
  const resolved = assert.async()
  const view = this.editView({withAssignment: true})
  return defer(() => {
    view.$discussionEditView.tabs('option', 'active', 0)
    view.showErrors({
      foo: {type: 'bar'},
      conditional_release: {type: 'bat'}
    })
    equal(1, view.$discussionEditView.tabs('option', 'active'))
    return resolved()
  })
})

test('switches to details tab if save error does not contain conditional release error', function(assert) {
  const resolved = assert.async()
  const view = this.editView({withAssignment: true})
  return defer(() => {
    view.$discussionEditView.tabs('option', 'active', 1)
    view.showErrors({
      foo: {type: 'bar'},
      baz: {type: 'bat'}
    })
    equal(0, view.$discussionEditView.tabs('option', 'active'))
    return resolved()
  })
})
