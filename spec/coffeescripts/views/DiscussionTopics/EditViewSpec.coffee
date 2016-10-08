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
  'jsx/shared/rce/RichContentEditor'
  'helpers/jquery.simulate'
], ($, _, SectionCollection, Assignment, DueDateList, Section, DiscussionTopic,
Announcement, DueDateOverrideView, EditView, AssignmentGroupCollection,
GroupCategorySelector, fakeENV, RichContentEditor) ->

  editView = (opts = {}) ->
    modelClass = if opts.isAnnouncement then Announcement else DiscussionTopic

    discussOpts = {}
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

    (app.assignmentGroupCollection = new AssignmentGroupCollection).contextAssetString = ENV.context_asset_string
    app.render()

  module 'EditView',
    setup: ->
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()
    editView: ->
      editView.apply(this, arguments)

  test 'renders', ->
    view = @editView()
    ok view

  test 'tells RCE to manage the parent', ->
    lne = @stub(RichContentEditor, 'loadNewEditor')
    EditView.prototype.loadNewEditor.call()
    ok lne.firstCall.args[1].manageParent, 'manageParent flag should be set'

  test 'does error message show on assignment point change with submissions', ->
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
    view = @editView()
    clock.tick(1)
    data = { group_category_id: 'new' }
    errors = view.validateBeforeSave(data, [])
    ok errors["groupCategorySelector"][0]["message"]
    clock.restore()

  test 'does not render #podcast_has_student_posts_container for non-course contexts', ->
    # not a course context because we are not passing contextType into the
    # EditView constructor
    view = @editView({ withAssignment: true, permissions: { CAN_MODERATE: true } })
    equal view.$el.find('#podcast_enabled').length, 1
    equal view.$el.find('#podcast_has_student_posts_container').length, 0

  module 'EditView - ConditionalRelease',
    setup: ->
      fakeENV.setup()
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
      ENV.CONDITIONAL_RELEASE_ENV = { assignment: { id: 1 }, jwt: 'foo' }
      $(document).on 'submit', -> false
    teardown: ->
      fakeENV.teardown()
      $(document).off 'submit'
    editView: ->
      editView.apply(this, arguments)

  test 'does not show conditional release tab when feature not enabled', ->
    ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    view = @editView()
    equal view.$el.find('#discussion-conditional-release-tab').length, 0
    equal view.$el.find('#discussion-edit-view').hasClass('ui-tabs'), false

  test 'shows disabled conditional release tab when feature enabled, but not assignment', ->
    view = @editView()
    view.renderTabs()
    view.loadConditionalRelease()
    equal view.$el.find('#discussion-conditional-release-tab').length, 1
    equal view.$discussionEditView.hasClass('ui-tabs'), true
    equal view.$discussionEditView.tabs("option", "disabled"), true

  test 'shows enabled conditional release tab when feature enabled, and assignment', ->
    view = @editView({ withAssignment: true })
    view.renderTabs()
    view.loadConditionalRelease()
    equal view.$el.find('#discussion-conditional-release-tab').length, 1
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
      view.showErrors({ foo: 'bar', conditional_release: 'bat' })
      equal 1, view.$discussionEditView.tabs('option', 'active')
      resolved()

  test 'switches to details tab if save error does not contain conditional release error', (assert) ->
    resolved = assert.async()
    view = @editView({ withAssignment: true })
    _.defer =>
      view.$discussionEditView.tabs('option', 'active', 1)
      view.showErrors({ foo: 'bar', baz: 'bat' })
      equal 0, view.$discussionEditView.tabs('option', 'active')
      resolved()
