# manage groups is for the add_group_category dialog
require [
  'compiled/models/Assignment'
  'compiled/views/assignments/EditView'
  'compiled/collections/SectionCollection'
  'compiled/models/DueDateList'
  'compiled/views/assignments/DueDateList'
  'compiled/views/assignments/DueDateOverride'
  'compiled/views/assignments/AssignmentGroupSelector'
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/views/assignments/PeerReviewsSelector'
  'manage_groups'
], (Assignment, EditView, SectionCollection, DueDateList, DueDateListView,
OverrideView, AssignmentGroupSelector, GroupCategorySelector,
PeerReviewsSelector) ->

  ENV.ASSIGNMENT.assignment_overrides = ENV.ASSIGNMENT_OVERRIDES

  assignment = new Assignment ENV.ASSIGNMENT
  assignment.urlRoot = ENV.URL_ROOT

  sectionList = new SectionCollection ENV.SECTION_LIST
  dueDateList = new DueDateList assignment.get('assignment_overrides'), sectionList, assignment

  assignmentGroupSelector = new AssignmentGroupSelector
    parentModel: assignment
    assignmentGroups: ENV?.ASSIGNMENT_GROUPS || []
  groupCategorySelector = new GroupCategorySelector
    parentModel: assignment
    groupCategories: ENV?.GROUP_CATEGORIES || []
  peerReviewsSelector = new PeerReviewsSelector
    parentModel: assignment

  editView = new EditView
    el: '#edit_assignment_form'
    model: assignment
    assignmentGroupSelector: assignmentGroupSelector
    groupCategorySelector: groupCategorySelector
    peerReviewsSelector: peerReviewsSelector
    views:
      'js-assignment-overrides': new OverrideView
        model: dueDateList
        views:
          'due-date-overrides': new DueDateListView(model: dueDateList)
      
  editView.render()
