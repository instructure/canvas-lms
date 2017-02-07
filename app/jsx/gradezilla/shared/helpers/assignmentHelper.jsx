define([
  'underscore'
], function (_) {
  function uniqueEffectiveDueDates(assignment) {
    const dueDates = _.map(assignment.effectiveDueDates, function(dueDateInfo) {
      const dueAt = dueDateInfo.due_at;
      return dueAt ? new Date(dueAt) : dueAt;
    });

    return _.uniq(dueDates, date => date ? date.toString() : date);
  }

  function getDueDateFromAssignment(assignment) {
    if (assignment.due_at) {
      return new Date(assignment.due_at);
    }

    const dueDates = uniqueEffectiveDueDates(assignment);
    return dueDates.length === 1 ? dueDates[0] : null;
  }

  const assignmentHelper = {
    compareByDueDate (a, b) {
      let aDate = getDueDateFromAssignment(a);
      let bDate = getDueDateFromAssignment(b);
      const aDateIsNull = _.isNull(aDate);
      const bDateIsNull = _.isNull(bDate);
      if (aDateIsNull && !bDateIsNull) { return 1 }
      if (!aDateIsNull && bDateIsNull) { return -1 }
      if (aDateIsNull && bDateIsNull) {
        const aHasMultipleDates = this.hasMultipleDueDates(a);
        const bHasMultipleDates = this.hasMultipleDueDates(b);
        if (aHasMultipleDates && !bHasMultipleDates) { return -1 }
        if (!aHasMultipleDates && bHasMultipleDates) { return 1 }
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
      return uniqueEffectiveDueDates(assignment).length > 1;
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
