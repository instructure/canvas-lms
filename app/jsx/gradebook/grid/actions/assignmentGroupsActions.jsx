define([
  'bower/reflux/dist/reflux',
  'jquery'
], function (Reflux, $) {
  var AssignmentGroupsActions = Reflux.createActions({
    load: { asyncResult: true },
    replaceAssignmentGroups: { asyncResult: false },
    replaceAssignment: {asyncResult: false}
  });

  AssignmentGroupsActions.load.listen(function() {
    var self = this;
    $.getJSON(ENV.GRADEBOOK_OPTIONS.assignment_groups_url)
      .done((json) => self.completed(json))
      .fail((jqxhr, textStatus, error) => self.failed(error));
  });

  return AssignmentGroupsActions;
});
