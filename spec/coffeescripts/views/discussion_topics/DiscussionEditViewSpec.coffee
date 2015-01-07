define [
  'jquery'
  'underscore'
  'compiled/collections/SectionCollection'
  'compiled/models/Assignment'
  'compiled/models/DueDateList'
  'compiled/models/Section'
  'compiled/models/DiscussionTopic'
  'compiled/views/assignments/DueDateList'
  'compiled/views/assignments/DueDateOverride'
  'compiled/views/DiscussionTopics/EditView'
  'compiled/collections/AssignmentGroupCollection'
  'compiled/views/assignments/GroupCategorySelector'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], ($, _, SectionCollection, Assignment, DueDateList, Section, DiscussionTopic,
    DueDateListView, DueDateOverrideView, EditView, AssignmentGroupCollection,
    GroupCategorySelector, fakeENV) ->

  defaultAssignmentOpts =
    name: 'Test Assignment'
    assignment_overrides: []

  editView = (assignmentOpts = {}) ->
    assignmentOpts = _.extend {}, assignmentOpts, defaultAssignmentOpts

    assignment = new Assignment assignmentOpts
    discussion = new DiscussionTopic
      assignment: assignment
    sectionList = new SectionCollection [Section.defaultDueDateSection()]
    dueDateList = new DueDateList assignment.get('assignment_overrides'), sectionList, assignment

    groupCategorySelector = new GroupCategorySelector
      parentModel: assignment
      groupCategories: ENV?.GROUP_CATEGORIES || []
    app = new EditView
      model: discussion
      assignmentGroupCollection: true
      groupCategorySelector: groupCategorySelector
      views:
        'js-assignment-overrides': new DueDateOverrideView
          model: dueDateList
          views:
            'due-date-overrides': new DueDateListView(model: dueDateList)

    (app.assignmentGroupCollection = new AssignmentGroupCollection).contextAssetString = ENV.context_asset_string
    app.permissions = {}
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
    view = editView has_submitted_submissions: true
    view.renderGroupCategoryOptions()
    ok view.$el.find('#discussion_point_change_warning')
    view.$el.find('#discussion_topic_assignment_points_possible').val(1)
    view.$el.find('#discussion_topic_assignment_points_possible').trigger("change")
    equal view.$el.find('#discussion_point_change_warning').attr('aria-expanded'), "true"
    view.$el.find('#discussion_topic_assignment_points_possible').val(0)
    view.$el.find('#discussion_topic_assignment_points_possible').trigger("change")
    equal view.$el.find('#discussion_point_change_warning').attr('aria-expanded'), "false"
