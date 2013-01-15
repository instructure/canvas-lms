# manage groups is for the add_group_category dialog
require [
  'compiled/models/Assignment'
  'compiled/views/assignments/EditView'
  'manage_groups'
], (Assignment, EditView) ->

  assignment = new Assignment ENV.ASSIGNMENT
  assignment.urlRoot = ENV.URL_ROOT

  editView = new EditView
    el: '#edit_assignment_form'
    model: assignment
  editView.render()
