define([
  'underscore'
], function (_) {
  var ColumnArranger = {
    compareByDueDate: function(a, b) {
      var aDate = this.getDueDateFromAssignment(a);
      var bDate = this.getDueDateFromAssignment(b);
      var aDateIsNull = _.isNull(aDate);
      var bDateIsNull = _.isNull(bDate);
      if (aDateIsNull && !bDateIsNull) return 1;
      if (!aDateIsNull && bDateIsNull) return -1;
      if (aDateIsNull && bDateIsNull) {
        if (this.hasMultipleDueDates(a) && !this.hasMultipleDueDates(b)) return -1;
        if (!this.hasMultipleDueDates(a) && this.hasMultipleDueDates(b)) return 1;
      }
      aDate = +aDate;
      bDate = +bDate;
      if (aDate === bDate) {
        var aName = a.name.toLowerCase();
        var bName = b.name.toLowerCase();
        if (aName === bName) return 0;
        return aName > bName ? 1 : -1;
      }
      return aDate - bDate;
    },

    hasMultipleDueDates: function(assignment) {
      return assignment.has_overrides && assignment.overrides.length > 1;
    },

    getDueDateFromAssignment: function(assignment) {
      if (assignment.due_at) return assignment.due_at;
      var overrides = assignment.overrides;
      if (!overrides || overrides.length > 1) return null;
      var overrideWithDueAt = _.find(overrides, override => override.due_at);
      return overrideWithDueAt ? overrideWithDueAt.due_at : null;
    },

    compareByAssignmentGroup: function(a, b) {
      var diffOfAssignmentGroupPosition = a.assignment_group_position - b.assignment_group_position;
      if (diffOfAssignmentGroupPosition === 0) {
        var diffOfAssignmentPosition = a.position - b.position;
        if (diffOfAssignmentPosition === 0) return 0;
        return diffOfAssignmentPosition;
      }
      return diffOfAssignmentGroupPosition;
    },

    getComparator: function(arrangeBy) {
      if (arrangeBy === 'due_date') return this.compareByDueDate.bind(this);
      if (arrangeBy === 'assignment_group') return this.compareByAssignmentGroup.bind(this);
    }
  };

  return ColumnArranger;
});