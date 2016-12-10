define([
  'underscore'
], function (_) {
  const getDueDateFromAssignment = function (assignment) {
    if (assignment.due_at) {
      return new Date(assignment.due_at);
    }
    const overrides = assignment.overrides;
    if (!overrides || overrides.length > 1) { return null }
    const overrideWithDueAt = _.find(overrides, override => override.due_at);
    return overrideWithDueAt ? new Date(overrideWithDueAt.due_at) : null;
  };

  const assignmentHelper = {
    compareByDueDate (a, b) {
      let aDate = getDueDateFromAssignment(a);
      let bDate = getDueDateFromAssignment(b);
      const aDateIsNull = _.isNull(aDate);
      const bDateIsNull = _.isNull(bDate);
      if (aDateIsNull && !bDateIsNull) { return 1 }
      if (!aDateIsNull && bDateIsNull) { return -1 }
      if (aDateIsNull && bDateIsNull) {
        if (this.hasMultipleDueDates(a) && !this.hasMultipleDueDates(b)) { return -1 }
        if (!this.hasMultipleDueDates(a) && this.hasMultipleDueDates(b)) { return 1 }
      }
      aDate = +aDate;
      bDate = +bDate;
      if (aDate === bDate) {
        const aName = a.name.toLowerCase();
        const bName = b.name.toLowerCase();
        if (aName === bName) { return 0 }
        return aName > bName ? 1 : -1;
      }
      return aDate - bDate;
    },

    hasMultipleDueDates (assignment) {
      return !!(
        assignment.has_overrides &&
          assignment.overrides &&
          assignment.overrides.length > 1
      );
    },

    getComparator (arrangeBy) {
      if (arrangeBy === 'due_date') {
        return this.compareByDueDate.bind(this);
      }
      if (arrangeBy === 'assignment_group') {
        return this.compareByAssignmentGroup.bind(this);
      }
    },

    compareByAssignmentGroup (a, b) {
      const diffOfAssignmentGroupPosition = a.assignment_group_position - b.assignment_group_position;
      if (diffOfAssignmentGroupPosition === 0) {
        const diffOfAssignmentPosition = a.position - b.position;
        if (diffOfAssignmentPosition === 0) { return 0 }
        return diffOfAssignmentPosition;
      }
      return diffOfAssignmentGroupPosition;
    }
  };

  return assignmentHelper;
});
