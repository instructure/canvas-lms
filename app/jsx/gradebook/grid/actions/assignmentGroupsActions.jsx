define([
  'reflux',
  'jsx/gradebook/grid/constants',
  'jquery'
], function (Reflux, GradebookConstants, $) {
  var AssignmentGroupsActions = Reflux.createActions({
    load: { asyncResult: true },
    replaceAssignmentGroups: { asyncResult: false },
    replaceAssignment: {asyncResult: false}
  });

  AssignmentGroupsActions.load.listen(function() {
    var self = this;
    $.getJSON(GradebookConstants.assignment_groups_url)
      .done((json) => self.completed(json))
      .fail((jqxhr, textStatus, error) => self.failed(error));
  });

  return AssignmentGroupsActions;
});
