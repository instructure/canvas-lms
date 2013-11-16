define [
  'jquery'
  'compiled/collections/SectionCollection'
  'compiled/models/Assignment'
  'compiled/models/DueDateList'
  'compiled/models/Section'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/DueDateList'
  'compiled/views/assignments/DueDateOverride'
  'compiled/views/assignments/EditView'
  'compiled/views/assignments/GradingTypeSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/views/assignments/PeerReviewsSelector'
  'helpers/jquery.simulate'
  'helpers/fakeENV'
], ($, SectionCollection, Assignment, DueDateList, Section,
  AssignmentGroupSelector, DueDateListView, DueDateOverrideView, EditView,
  GradingTypeSelector, GroupCategorySelector, PeerReviewsSelector) ->


  fixtures = $('#fixtures')

  editView = ->
    $('<form id="content"></form>').appendTo fixtures

    assignment = new Assignment
      name: 'Test Assignment'
      assignment_overrides: []

    sectionList = new SectionCollection [Section.defaultDueDateSection()]
    dueDateList = new DueDateList assignment.get('assignment_overrides'), sectionList, assignment

    assignmentGroupSelector = new AssignmentGroupSelector
      parentModel: assignment
      assignmentGroups: ENV?.ASSIGNMENT_GROUPS || []
    gradingTypeSelector = new GradingTypeSelector
      parentModel: assignment
    groupCategorySelector = new GroupCategorySelector
      parentModel: assignment
      groupCategories: ENV?.GROUP_CATEGORIES || []
    peerReviewsSelector = new PeerReviewsSelector
      parentModel: assignment

    app = new EditView
      el: '#content'
      model: assignment
      assignmentGroupSelector: assignmentGroupSelector
      gradingTypeSelector: gradingTypeSelector
      groupCategorySelector: groupCategorySelector
      peerReviewsSelector: peerReviewsSelector
      views:
        'js-assignment-overrides': new DueDateOverrideView
          model: dueDateList
          views:
            'due-date-overrides': new DueDateListView(model: dueDateList)

    sinon.stub(app, "_initializeWikiSidebar")
    app.render()

  module 'EditView',
    teardown: ->
      fixtures.empty()

  test 'renders', ->
    view = editView()
    equal view.$('#assignment_name').val(), 'Test Assignment'

  test 'rejects a letter for points_possible', ->
    view = editView()
    data = points_possible: 'a'
    errors = view.validateBeforeSave(data, [])
    equal errors['points_possible'][0]['message'], 'Points possible must be a number'
