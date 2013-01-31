# manage groups is for the add_group_category dialog
require [
  'compiled/models/Assignment'
  'compiled/views/assignments/EditView'
  'compiled/collections/SectionCollection'
  'compiled/models/DueDateList'
  'compiled/views/assignments/DueDateList'
  'compiled/views/assignments/DueDateOverride'
  'manage_groups'
], (Assignment, EditView, SectionCollection, DueDateList, DueDateListView, OverrideView) ->

  ENV.ASSIGNMENT.assignment_overrides = ENV.ASSIGNMENT_OVERRIDES
  assignment = new Assignment ENV.ASSIGNMENT
  sectionList = new SectionCollection ENV.SECTION_LIST
  dueDateList =
    new DueDateList assignment.get('assignment_overrides'), sectionList, assignment
  assignment.urlRoot = ENV.URL_ROOT
  editView = new EditView
    el: '#edit_assignment_form'
    model: assignment
    views:
      'js-assignment-overrides': new OverrideView
        model: dueDateList
        views:
          'due-date-overrides': new DueDateListView(model: dueDateList)
      
  editView.render()
