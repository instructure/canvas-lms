#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'compiled/collections/SectionCollection'
  'compiled/models/Assignment'
  'compiled/models/DueDateList'
  'compiled/models/Section'
  'compiled/models/DiscussionTopic'
  'compiled/models/Announcement'
  'compiled/views/assignments/DueDateOverride'
  'compiled/views/DiscussionTopics/EditView'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/GroupCategorySelector'
  'helpers/fakeENV'
  'helpers/assertions'
  'jsx/shared/rce/RichContentEditor'
  'helpers/jquery.simulate'
], (
  $,
  _,
  SectionCollection,
  Assignment,
  DueDateList,
  Section,
  DiscussionTopic,
  Announcement,
  DueDateOverrideView,
  EditView,
  AssignmentGroupCollection,
  GroupCategorySelector,
  fakeENV,
  assertions,
  RichContentEditor) ->

  editView = (opts = {}, discussOpts = {}) ->
    modelClass = if opts.isAnnouncement then Announcement else DiscussionTopic

    if opts.withAssignment
      assignmentOpts = _.extend {}, opts.assignmentOpts,
        name: 'Test Assignment'
        assignment_overrides: []
      discussOpts.assignment = assignmentOpts
    discussion = new modelClass(discussOpts, parse: true)
    assignment = discussion.get('assignment')
    sectionList = new SectionCollection [Section.defaultDueDateSection()]
    dueDateList = new DueDateList assignment.get('assignment_overrides'), sectionList, assignment

    app = new EditView
      model: discussion
      permissions: opts.permissions || {}
      views:
        'js-assignment-overrides': new DueDateOverrideView
          model: dueDateList
          views: {}
      lockedItems: opts.lockedItems || {}

    (app.assignmentGroupCollection = new AssignmentGroupCollection).contextAssetString = ENV.context_asset_string
    app.render()

  nameLengthHelper = (view, length, maxNameLengthRequiredForAccount, maxNameLength, postToSis) ->
    ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
    ENV.MAX_NAME_LENGTH = maxNameLength
    ENV.IS_LARGE_ROSTER = true
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    title = 'a'.repeat(length)
    assignment = view.assignment
    assignment.attributes.post_to_sis = postToSis
    return view.validateBeforeSave({title: title, set_assignment: '1', assignment: assignment}, [])

  QUnit.module 'EditView',
    setup: ->
      fakeENV.setup()
      @server = sinon.fakeServer.create(respondImmediately: true)
    teardown: ->
      @server.restore()
      fakeENV.teardown()
    editView: ->
      editView.apply(this, arguments)

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @editView(), done, {'a11yReport': true}

  test 'renders', ->
    view = @editView()
    ok view

  test 'tells RCE to manage the parent', ->
    lne = @stub(RichContentEditor, 'loadNewEditor')
    view = @editView()
    view.loadNewEditor()
    ok lne.firstCall.args[1].manageParent, 'manageParent flag should be set'

  test 'does not tell RCE to manage the parent of locked content', ->
    lne = @stub(RichContentEditor, 'loadNewEditor')
    view = @editView
      lockedItems: {content: true}
    view.loadNewEditor()
    ok lne.callCount==0, 'RCE not called'

  test 'shows error message on assignment point change with submissions', ->
    view = @editView
      withAssignment: true,
      assignmentOpts: { has_submitted_submissions: true }
    view.renderGroupCategoryOptions()
    ok view.$el.find('#discussion_point_change_warning'), 'rendered change warning'
    view.$el.find('#discussion_topic_assignment_points_possible').val(1)
    view.$el.find('#discussion_topic_assignment_points_possible').trigger("change")
    equal view.$el.find('#discussion_point_change_warning').attr('aria-expanded'), "true", 'change warning aria-expanded true'
    view.$el.find('#discussion_topic_assignment_points_possible').val(0)
    view.$el.find('#discussion_topic_assignment_points_possible').trigger("change")
    equal view.$el.find('#discussion_point_change_warning').attr('aria-expanded'), "false", 'change warning aria-expanded false'

  test 'hides the published icon for announcements', ->
    view = @editView(isAnnouncement: true)
    equal view.$el.find('.published-status').length, 0

  test 'validates the group category for non-assignment discussions', ->
    clock = sinon.useFakeTimers()
    view = @editView(permissions: {CAN_SET_GROUP: true})
    clock.tick(1)
    data = { group_category_id: 'blank' }
    errors = view.validateBeforeSave(data, [])
    ok errors["newGroupCategory"][0]["message"]
    clock.restore()

  test 'does not render #podcast_has_student_posts_container for non-course contexts', ->
    # not a course context because we are not passing contextType into the
    # EditView constructor
    view = @editView({ withAssignment: true, permissions: { CAN_MODERATE: true } })
    equal view.$el.find('#podcast_enabled').length, 1
    equal view.$el.find('#podcast_has_student_posts_container').length, 0

  test 'routes to discussion details normally', ->
    view = @editView({}, { html_url: 'http://foo' })
    equal view.locationAfterSave({}), 'http://foo'

  test 'routes to return_to', ->
    view = @editView({}, { html_url: 'http://foo' })
    equal view.locationAfterSave({ return_to: 'http://bar' }), 'http://bar'

  test 'cancels to env normally', ->
    ENV.CANCEL_TO = 'http://foo'
    view = @editView()
    equal view.locationAfterCancel({}), 'http://foo'

  test 'cancels to return_to', ->
    ENV.CANCEL_TO = 'http://foo'
    view = @editView()
    equal view.locationAfterCancel({ return_to: 'http://bar' }), 'http://bar'

  test 'shows todo checkbox', ->
    ENV.STUDENT_PLANNER_ENABLED = true
    view = @editView()
    equal view.$el.find('#allow_todo_date').length, 1
    equal view.$el.find('#todo_date_input')[0].style.display, 'none'

  test 'shows todo input when todo checkbox is selected', ->
    ENV.STUDENT_PLANNER_ENABLED = true
    view = @editView()
    view.$el.find('#allow_todo_date').prop('checked', true)
    view.$el.find('#allow_todo_date').trigger('change')
    equal view.$el.find('#todo_date_input')[0].style.display, 'block'

  test 'shows todo input with date when given date', ->
    ENV.STUDENT_PLANNER_ENABLED = true
    view = @editView {}, {todo_date: '2017-01-03'}

    equal view.$el.find('#allow_todo_date').prop('checked'), true
    equal view.$el.find('#todo_date').val(), 'Jan 3, 2017 at 12am'

  test 'does not show todo checkbox without permission', ->
    ENV.STUDENT_PLANNER_ENABLED = false
    view = @editView()
    equal view.$el.find('#allow_todo_date').length, 0

  test 'does not show todo date elements when grading is enabled', ->
    ENV.STUDENT_PLANNER_ENABLED = true
    view = @editView()
    view.$el.find('#use_for_grading').prop('checked', true)
    view.$el.find('#use_for_grading').trigger('change')
    equal view.$el.find('#todo_options')[0].style.display, 'none'

  test 'does save todo date if allow_todo_date is checked and discussion is not graded', ->
    ENV.STUDENT_PLANNER_ENABLED = true
    todo_date = new Date('2017-05-25T08:00:00-0800')
    view = @editView()
    view.renderGroupCategoryOptions()
    view.$el.find('#allow_todo_date').prop('checked', true)
    view.$el.find('#allow_todo_date').trigger('change')
    view.$el.find('#todo_date').val(todo_date.toISOString())
    view.$el.find('#todo_date').trigger('change')
    formData = view.getFormData()
    equal formData.todo_date.toString(), todo_date.toString()

  test 'does not save todo date if allow_todo_date is not checked', ->
    ENV.STUDENT_PLANNER_ENABLED = true
    view = @editView()
    view.$el.find('#todo_date').val('2017-01-03')
    view.$el.find('#todo_date').trigger('change')
    view.renderGroupCategoryOptions()
    formData = view.getFormData()
    equal formData.todo_date, null

  test 'does not save todo date if discussion is graded', ->
    ENV.STUDENT_PLANNER_ENABLED = true
    view = @editView()
    view.$el.find('#todo_date').val('2017-01-03')
    view.$el.find('#todo_date').trigger('change')
    view.$el.find('#use_for_grading').prop('checked', true)
    view.$el.find('#use_for_grading').trigger('change')
    view.renderGroupCategoryOptions()
    formData = view.getFormData()
    equal formData.todo_date, null

  QUnit.module 'EditView - Sections Specific',
    test "allows discussion to save when section specific has errors has no section", ->
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.DISCUSSION_TOPIC = {
        ATTRIBUTES: {
          is_announcement: false
        }
      }
      view = @editView({ withAssignment: true})
      title = 'a'.repeat(10)
      assignment = view.assignment
      assignment.attributes.post_to_sis = '1'
      errors = view.validateBeforeSave({
        title: title,
        set_assignment: '1',
        assignment: assignment,
        specific_sections: null
      }, [])
      equal Object.keys(errors).length, 0

    test "allows announcement to save when section specific has a section", ->
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.DISCUSSION_TOPIC = {
        ATTRIBUTES: {
          is_announcement: true
        }
      }
      view = @editView({ withAssignment: false })
      title = 'a'.repeat(10)
      assignment = view.assignment
      assignment.attributes.post_to_sis = '1'
      errors = view.validateBeforeSave({
        title: title,
        specific_sections: ["fake_section"]
      }, [])
      equal Object.keys(errors).length, 0

    test "allows group announcements to be saved without a section", ->
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.CONTEXT_ID = 1
      ENV.context_asset_string = "group_1"
      ENV.DISCUSSION_TOPIC = {
        ATTRIBUTES: {
          is_announcement: true
        }
      }

      view = @editView({ withAssignment: false })
      title = 'a'.repeat(10)
      assignment = view.assignment
      assignment.attributes.post_to_sis = '1'
      errors = view.validateBeforeSave({
        title: title,
        specific_sections: null
      }, [])
      equal Object.keys(errors).length, 0

    test "require section for course announcements if enabled", ->
      ENV.should_log = true
      ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED = true
      ENV.CONTEXT_ID = 1
      ENV.context_asset_string = "course_1"
      ENV.DISCUSSION_TOPIC = {
        ATTRIBUTES: {
          is_announcement: true
        }
      }
      view = @editView({ withAssignment: false })
      title = 'a'.repeat(10)
      assignment = view.assignment
      assignment.attributes.post_to_sis = '1'
      errors = view.validateBeforeSave({
        title: title,
        specific_sections: null
      }, [])
      equal Object.keys(errors).length, 1
      equal Object.keys(errors)[0], 'specific_sections'

  QUnit.module 'EditView - ConditionalRelease',
    setup: ->
      fakeENV.setup()
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
      $(document).on 'submit', -> false
      @server = sinon.fakeServer.create(respondImmediately: true)
    teardown: ->
      @server.restore()
      fakeENV.teardown()
      $(document).off 'submit'
    editView: ->
      editView.apply(this, arguments)

  test 'does not show conditional release tab when feature not enabled', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    view = @editView()
    equal view.$el.find('#mastery-paths-editor').length, 0
    equal view.$el.find('#discussion-edit-view').hasClass('ui-tabs'), false

  test 'shows disabled conditional release tab when feature enabled, but not assignment', ->
    view = @editView()
    view.renderTabs()
    view.loadConditionalRelease()
    equal view.$el.find('#mastery-paths-editor').length, 1
    equal view.$discussionEditView.hasClass('ui-tabs'), true
    equal view.$discussionEditView.tabs("option", "disabled"), true

  test 'shows enabled conditional release tab when feature enabled, and assignment', ->
    view = @editView({ withAssignment: true })
    view.renderTabs()
    view.loadConditionalRelease()
    equal view.$el.find('#mastery-paths-editor').length, 1
    equal view.$discussionEditView.hasClass('ui-tabs'), true
    equal view.$discussionEditView.tabs("option", "disabled"), false

  test 'enables conditional release tab when changed to assignment', ->
    view = @editView()
    view.loadConditionalRelease()
    view.renderTabs()
    equal view.$discussionEditView.tabs("option", "disabled"), true

    view.$useForGrading.prop('checked', true)
    view.$useForGrading.trigger('change')
    equal view.$discussionEditView.tabs("option", "disabled"), false

  test 'disables conditional release tab when changed from assignment', ->
    view = @editView({ withAssignment: true })
    view.loadConditionalRelease()
    view.renderTabs()
    equal view.$discussionEditView.tabs("option", "disabled"), false

    view.$useForGrading.prop('checked', false)
    view.$useForGrading.trigger('change')
    equal view.$discussionEditView.tabs("option", "disabled"), true

  test 'renders conditional release tab content', ->
    view = @editView({ withAssignment: true })
    view.loadConditionalRelease()
    equal 1, view.$conditionalReleaseTarget.children().size()

  test "has an error when a title is 257 chars", ->
    view = @editView({ withAssignment: true})
    errors = nameLengthHelper(view, 257, false, 30, '1')
    equal errors["title"][0]["message"], "Title is too long, must be under 257 characters"

  test "allows dicussion to save when a title is 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true", ->
    view = @editView({ withAssignment: true})
    errors = nameLengthHelper(view, 256, false, 30, '1')
    equal errors.length, 0

  test "has an error when a title > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true", ->
    view = @editView({ withAssignment: true})
    errors = nameLengthHelper(view, 40, true, 30, '1')
    equal errors["title"][0]["message"], "Title is too long, must be under 31 characters"

  test "allows discussion to save when title > MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is false", ->
    view = @editView({ withAssignment: true})
    errors = nameLengthHelper(view, 40, true, 30, '0')
    equal errors.length, 0

  test "allows discussion to save when title < MAX_NAME_LENGTH chars if MAX_NAME_LENGTH is custom, required and post_to_sis is true", ->
    view = @editView({ withAssignment: true})
    errors = nameLengthHelper(view, 30, true, 40, '1')
    equal errors.length, 0

  test 'conditional release editor is updated on tab change', ->
    view = @editView({ withAssignment: true })
    view.renderTabs()
    view.renderGroupCategoryOptions()
    view.loadConditionalRelease()
    stub = @stub(view.conditionalReleaseEditor, 'updateAssignment')
    view.$discussionEditView.tabs("option", "active", 1)
    ok stub.calledOnce

    stub.reset()
    view.$discussionEditView.tabs("option", "active", 0)
    view.onChange()
    view.$discussionEditView.tabs("option", "active", 1)
    ok stub.calledOnce

  test 'validates conditional release', (assert) ->
    resolved = assert.async()
    view = @editView({ withAssignment: true })
    _.defer =>
      stub = @stub(view.conditionalReleaseEditor, 'validateBeforeSave').returns 'foo'
      errors = view.validateBeforeSave(view.getFormData(), {})
      ok errors['conditional_release'] == 'foo'
      resolved()

  test 'calls save in conditional release', (assert) ->
    resolved = assert.async()
    view = @editView({ withAssignment: true })
    _.defer =>
      superPromise = $.Deferred().resolve({}).promise()
      crPromise = $.Deferred().resolve({}).promise()
      mockSuper = sinon.mock(EditView.__super__)
      mockSuper.expects('saveFormData').returns superPromise
      stub = @stub(view.conditionalReleaseEditor, 'save').returns crPromise

      finalPromise = view.saveFormData()
      finalPromise.then ->
        mockSuper.verify()
        ok stub.calledOnce
        resolved()

  test 'does not call conditional release save for an announcement', (assert) ->
    resolved = assert.async()
    view = @editView({ isAnnouncement: true })
    _.defer =>
      superPromise = $.Deferred().resolve({}).promise()
      mockSuper = sinon.mock(EditView.__super__)
      mockSuper.expects('saveFormData').returns superPromise

      savePromise = view.saveFormData()
      savePromise.then ->
        mockSuper.verify()
        notOk view.conditionalReleaseEditor
        resolved()

  test 'switches to conditional tab if save error contains conditional release error', (assert) ->
    resolved = assert.async()
    view = @editView({ withAssignment: true })
    _.defer =>
      view.$discussionEditView.tabs('option', 'active', 0)
      view.showErrors({
        foo: {type: 'bar'},
        conditional_release: {type: 'bat'}
      })
      equal 1, view.$discussionEditView.tabs('option', 'active')
      resolved()

  test 'switches to details tab if save error does not contain conditional release error', (assert) ->
    resolved = assert.async()
    view = @editView({ withAssignment: true })
    _.defer =>
      view.$discussionEditView.tabs('option', 'active', 1)
      view.showErrors({
        foo: {type: 'bar'},
        baz: {type: 'bat'}
      })
      equal 0, view.$discussionEditView.tabs('option', 'active')
      resolved()
