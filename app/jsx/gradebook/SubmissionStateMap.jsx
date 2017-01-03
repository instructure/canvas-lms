define([
  'underscore',
  'jquery',
  'timezone',
  'i18n!gradebook2',
  'jsx/gradebook/AssignmentOverrideHelper',
  'jsx/grading/helpers/GradingPeriodsHelper'
], function(_, $, tz, I18n, AssignmentOverrideHelper, GradingPeriodsHelper) {

  const TOOLTIP_KEYS = {
    NOT_IN_ANY_GP: "not_in_any_grading_period",
    IN_ANOTHER_GP: "in_another_grading_period",
    IN_CLOSED_GP: "in_closed_grading_period",
    NONE: null
  };

  function visibleToStudent(assignment, student) {
    if (!assignment.only_visible_to_overrides) return true;
    return _.contains(assignment.assignment_visibility, student.id);
  }

  function indexOverrides(assignments, students) {
    return _.reduce(assignments, function(overrides, assignment) {
      overrides[assignment.id] =
        AssignmentOverrideHelper.effectiveDueDatesForAssignment(
          assignment, assignment.overrides, students
        );
      return overrides;
    }, {});
  }

  function cellMapForSubmission(assignment, student, effectiveDueAt, gradingPeriodsEnabled, selectedGradingPeriodID, gradingPeriods, isAdmin) {
    if (!visibleToStudent(assignment, student)) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NONE };
    } else if (gradingPeriodsEnabled) {
      return cellMappingsForMultipleGradingPeriods(assignment, student, effectiveDueAt, selectedGradingPeriodID, gradingPeriods, isAdmin);
    } else {
      return { locked: false, hideGrade: false, tooltip: TOOLTIP_KEYS.NONE };
    }
  }

  function cellMappingsForMultipleGradingPeriods(assignment, student, effectiveDueAt, selectedGradingPeriodID, gradingPeriods, isAdmin) {
    const specificPeriodSelected = !GradingPeriodsHelper.isAllGradingPeriods(selectedGradingPeriodID);

    if (effectiveDueAt === undefined) {
      const tooltip = specificPeriodSelected ? TOOLTIP_KEYS.NOT_IN_ANY_GP : TOOLTIP_KEYS.NONE;
      return { locked: specificPeriodSelected, hideGrade: specificPeriodSelected, tooltip };
    }

    const gradingPeriod = new GradingPeriodsHelper(gradingPeriods).gradingPeriodForDueAt(effectiveDueAt);
    if (specificPeriodSelected && !gradingPeriod) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NOT_IN_ANY_GP };
    } else if (specificPeriodSelected && selectedGradingPeriodID !== gradingPeriod.id) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.IN_ANOTHER_GP };
    } else if (!isAdmin && (gradingPeriod || {}).isClosed) {
      return { locked: true, hideGrade: false, tooltip: TOOLTIP_KEYS.IN_CLOSED_GP };
    } else {
      return { locked: false, hideGrade: false, tooltip: TOOLTIP_KEYS.NONE };
    }
  }

  class SubmissionState {
    constructor({ gradingPeriodsEnabled, selectedGradingPeriodID, gradingPeriods, isAdmin }) {
      this.gradingPeriodsEnabled = gradingPeriodsEnabled;
      this.selectedGradingPeriodID = selectedGradingPeriodID;
      this.gradingPeriods = gradingPeriods;
      this.isAdmin = isAdmin;
      this.overrides = {};
      this.submissionCellMap = {};
      this.submissionMap = {};
    }

    setup(students, assignments) {
      const newOverrides = indexOverrides(assignments, students);
      this.overrides = $.extend(true, this.overrides, newOverrides);

      students.forEach((student) => {
        this.submissionCellMap[student.id] = {};
        this.submissionMap[student.id] = {};
        _.each(assignments, (assignment) => {
          this.setSubmissionCellState(student, assignment, student[`assignment_${assignment.id}`]);
        });
      });
    }

    setSubmissionCellState(student, assignment, submission = { assignment_id: assignment.id, user_id: student.id }) {
      this.submissionMap[student.id][assignment.id] = submission;
      const params = [
        assignment,
        student,
        this.overrides[assignment.id][student.id],
        this.gradingPeriodsEnabled,
        this.selectedGradingPeriodID,
        this.gradingPeriods,
        this.isAdmin
      ];

      this.submissionCellMap[student.id][assignment.id] = cellMapForSubmission(...params);
    }

    getSubmission(user_id, assignment_id) {
      return (this.submissionMap[user_id] || {})[assignment_id];
    }

    getSubmissionState({ user_id, assignment_id }) {
      return (this.submissionCellMap[user_id] || {})[assignment_id];
    }
  };

  return SubmissionState;
})
