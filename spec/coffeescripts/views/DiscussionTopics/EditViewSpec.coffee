define [
  'jquery'
  'underscore'
  'compiled/collections/SectionCollection'
  'compiled/models/Assignment'
  'compiled/models/DueDateList'
  'compiled/models/Section'
  'compiled/models/DiscussionTopic'
  'compiled/models/Announcement'
  'compiled/views/assignments/DueDateList'
  'compiled/views/assignments/DueDateOverride'
  'compiled/views/DiscussionTopics/EditView'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/GroupCategorySelector'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], ($, _, SectionCollection, Assignment, DueDateList, Section, DiscussionTopic,
Announcement, DueDateListView, DueDateOverrideView, EditView,
AssignmentGroupCollection, GroupCategorySelector, fakeENV) ->

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
      permissions: {}
      views:
        'js-assignment-overrides': new DueDateOverrideView
          model: dueDateList
          views:
            'due-date-overrides': new DueDateListView(model: dueDateList)

    (app.assignmentGroupCollection = new AssignmentGroupCollection).contextAssetString = ENV.context_asset_string
    sinon.stub(app, "_initializeWikiSidebar")
    app.render()

  module 'EditView',
    setup: ->
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()

  test 'renders', ->
    view = editView()
    ok view

  test 'does error message show on assignment point change with submissions', ->
    view = editView
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
    view = editView(isAnnouncement: true)
    equal view.$el.find('.published-status').length, 0

  test 'validates the group category for non-assignment discussions', ->
    clock = sinon.useFakeTimers()
    view = editView()
    clock.tick(1)
    data = { group_category_id: 'new' }
    errors = view.validateBeforeSave(data, [])
    ok errors["groupCategorySelector"][0]["message"]
    clock.restore()
