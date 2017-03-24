import _ from 'underscore'

function dateForComparison (date) {
  if (date == null) return date;

  const comparisonDate = new Date(date);
  comparisonDate.setSeconds(0, 0);
  return comparisonDate;
}

const assignmentClosedForStudent = (student, {due_at, only_visible_to_overrides, gradingPeriods, assignmentOverrides}) => {
  const potentialDueDates = only_visible_to_overrides ?
    assignmentOverrides :
    [{default: true, due_at: due_at}, ...assignmentOverrides];
  const dueDate = dueDateForStudent(student, potentialDueDates);
  const gp = gradingPeriodForDate(dueDate, gradingPeriods);
  return gp && new Date(gp.close_date) < new Date();
}

const gradingPeriodForDate = (date, gradingPeriods) => {
  if (date == null) {
    return _.last(gradingPeriods);
  } else {
    return gradingPeriods.find((gp) => {
      return (
        dateForComparison(date) > dateForComparison(gp.start_date) &&
        dateForComparison(date) <= dateForComparison(gp.end_date)
      );
    });
  }
}

const dueDateForStudent = (student, dueDates) => {
  const applicableDueDates = dueDates.filter(function(o) {
    if (o.default) {
      return true;
    }
    if (o.student_ids && _.include(o.student_ids, student.id)) {
      return true;
    }
    if (o.course_section_id != null &&
        _.include(student.section_ids, o.course_section_id)) {
      return true;
    }
  }).map(o => o.due_at);

  return _.last(applicableDueDates.sort());
};

export default {assignmentClosedForStudent, gradingPeriodForDate, dueDateForStudent}
