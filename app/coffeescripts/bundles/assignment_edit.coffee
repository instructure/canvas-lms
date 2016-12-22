# manage groups is for the add_group_category dialog
require [
  'compiled/models/Section'
  'compiled/models/Assignment'
  'compiled/views/assignments/EditHeaderView'
  'compiled/views/assignments/EditView'
  'compiled/collections/SectionCollection'
  'compiled/models/DueDateList'
  'compiled/views/assignments/DueDateOverride'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GradingTypeSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/views/assignments/PeerReviewsSelector'
  'grading_standards'
  'manage_groups'
], (Section, Assignment, EditHeaderView, EditView, SectionCollection,

  DueDateList, OverrideView, AssignmentGroupSelector,
  GradingTypeSelector, GroupCategorySelector, PeerReviewsSelector) ->

  ENV.ASSIGNMENT.assignment_overrides = ENV.ASSIGNMENT_OVERRIDES

  userIsAdmin = ENV.current_user_roles.includes('admin')

  assignment = new Assignment ENV.ASSIGNMENT
  assignment.urlRoot = ENV.URL_ROOT

  sectionList = new SectionCollection ENV.SECTION_LIST
  dueDateList = new DueDateList assignment.get('assignment_overrides'), sectionList, assignment

  assignmentGroupSelector = new AssignmentGroupSelector
    parentModel: assignment
    assignmentGroups: ENV?.ASSIGNMENT_GROUPS || []
  gradingTypeSelector = new GradingTypeSelector
    parentModel: assignment
  groupCategorySelector = new GroupCategorySelector
    parentModel: assignment
    groupCategories: ENV?.GROUP_CATEGORIES || []
    inClosedGradingPeriod: assignment.inClosedGradingPeriod()
  peerReviewsSelector = new PeerReviewsSelector
    parentModel: assignment

  headerEl = if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
      '#edit_assignment_header-cr'
    else
      '#edit_assignment_header'

  editView = new EditView
    el: '#edit_assignment_form'
    model: assignment
    assignmentGroupSelector: assignmentGroupSelector
    gradingTypeSelector: gradingTypeSelector
    groupCategorySelector: groupCategorySelector
    peerReviewsSelector: peerReviewsSelector
    views:
      'js-assignment-overrides': new OverrideView
        model: dueDateList
        views: {}

  editHeaderView = new EditHeaderView
    el: headerEl
    model: assignment
    userIsAdmin: userIsAdmin
    views:
      'edit_assignment_form': editView

  editHeaderView.render()
