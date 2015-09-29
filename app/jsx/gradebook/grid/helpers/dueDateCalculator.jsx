define([
  'compiled/collections/DateGroupCollection',
  'underscore'
], function(DateGroupCollection, _) {
  var DueDateCalculator, exists;

  exists = function(value) {
    return value !== null && value !== undefined;
  };

  DueDateCalculator = function(assignment) {
    this.assignment = assignment;
  };

  DueDateCalculator.prototype.dueDate = function() {
    var dueAt, allDates, dueDate;

    dueAt = this.assignment.due_at;
    allDates = this.assignment.all_dates;

    if (!exists(dueAt)) {
      dueDate = _.find(allDates, section =>
                       exists(section.due_at));
      if (exists(dueDate)) return dueDate.due_at.toISOString();
    } else {
      return dueAt;
    }

    return null;
  };

  return DueDateCalculator;
});
