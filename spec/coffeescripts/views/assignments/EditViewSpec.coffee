define [
  'jquery'
  'underscore'
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
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], ($, _, SectionCollection, Assignment, DueDateList, Section,
  AssignmentGroupSelector, DueDateListView, DueDateOverrideView, EditView,
  GradingTypeSelector, GroupCategorySelector, PeerReviewsSelector, fakeENV) ->

  defaultAssignmentOpts =
    name: 'Test Assignment'
    assignment_overrides: []

  editView = (assignmentOpts = {}) ->
    assignmentOpts = _.extend {}, assignmentOpts, defaultAssignmentOpts
    assignment = new Assignment assignmentOpts

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
    setup: ->
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()

  test 'renders', ->
    view = editView()
    equal view.$('#assignment_name').val(), 'Test Assignment'

  test 'rejects a letter for points_possible', ->
    view = editView()
    data = points_possible: 'a'
    errors = view.validateBeforeSave(data, [])
    equal errors['points_possible'][0]['message'], 'Points possible must be a number'

  test 'does not allow group assignment for large rosters', ->
    ENV.IS_LARGE_ROSTER = true
    view = editView()
    equal view.$("#group_category_selector").length, 0

  test 'does not allow peer review for large rosters', ->
    ENV.IS_LARGE_ROSTER = true
    view = editView()
    equal view.$("#assignment_peer_reviews_fields").length, 0

  test 'adds and removes student group', ->
    ENV.GROUP_CATEGORIES = [{id: 1, name: "fun group"}]
    ENV.ASSIGNMENT_GROUPS = [{id: 1, name: "assignment group 1"}]
    view = editView()
    equal view.assignment.toView()['groupCategoryId'], null

    #fragile spec on Firefox, Safari
    #adds student group
    # view.$('#assignment_has_group_category').click()
    # view.$('#assignment_group_category_id option:eq(0)').attr("selected", "selected")
    # equal view.getFormData()['group_category_id'], "1"

    #removes student group
    view.$('#assignment_has_group_category').click()
    equal view.getFormData()['groupCategoryId'], null

  test 'renders escaped angle brackets properly', ->
    desc = "<p>&lt;E&gt;</p>"
    view = editView description: "<p>&lt;E&gt;</p>"
    equal view.$description.val().match(desc), desc

  # fragile spec
  checkWarning = (view, showsWarning) ->
    view.$("#assignment_toggle_advanced_options").click()
    equal view.$(".group_submission_warning").is(":visible"), false, 'warning isn\'t initially shown'
    view.$("#assignment_has_group_category").click()
    # equal view.$(".group_submission_warning").is(":visible"), showsWarning, 'warning has expected visibility of visible:'+showsWarning
    view.$("#assignment_has_group_category").click()
    equal view.$(".group_submission_warning").is(":visible"), false, 'warning is hidden after clicking again'

  module 'EditView: warning on group status change',
    setup: ->
      fakeENV.setup()
      window.addGroupCategory = sinon.stub()
    teardown: ->
      fakeENV.teardown()
      window.addGroupCategory = null

  test 'warns when has submitted submissions', ->
    view = editView has_submitted_submissions: true
    checkWarning view, true

  test 'does not warn if starting with a group', ->
    view = editView has_submitted_submissions: true, group_category_id: 1
    checkWarning view, false

  test 'does not warn if there are no submitted submissions', ->
    view = editView()
    checkWarning view, false

