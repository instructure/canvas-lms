define([
  'underscore',
  'timezone',
  'i18n!gradebook',
  'jsx/grading/helpers/GradingPeriodsHelper'
], function(_, tz, I18n, GradingPeriodsHelper) {

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

  function cellMapForSubmission(assignment, student, gradingPeriodsEnabled, selectedGradingPeriodID, isAdmin) {
    if (!visibleToStudent(assignment, student)) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NONE };
    } else if (gradingPeriodsEnabled) {
      return cellMappingsForMultipleGradingPeriods(assignment, student, selectedGradingPeriodID, isAdmin);
    } else {
      return { locked: false, hideGrade: false, tooltip: TOOLTIP_KEYS.NONE };
    }
  }

  function submissionGradingPeriodInformation(assignment, student) {
    const submissionInfo = assignment.effectiveDueDates[student.id] || {};
    return {
      gradingPeriodID: submissionInfo.grading_period_id,
      inClosedGradingPeriod: submissionInfo.in_closed_grading_period
    };
  }

  function cellMappingsForMultipleGradingPeriods(assignment, student, selectedGradingPeriodID, isAdmin) {
    const specificPeriodSelected = !GradingPeriodsHelper.isAllGradingPeriods(selectedGradingPeriodID);
    const { gradingPeriodID, inClosedGradingPeriod } = submissionGradingPeriodInformation(assignment, student);

    if (specificPeriodSelected && !gradingPeriodID) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NOT_IN_ANY_GP };
    } else if (specificPeriodSelected && selectedGradingPeriodID != gradingPeriodID) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.IN_ANOTHER_GP };
    } else if (!isAdmin && inClosedGradingPeriod) {
      return { locked: true, hideGrade: false, tooltip: TOOLTIP_KEYS.IN_CLOSED_GP };
    } else {
      return { locked: false, hideGrade: false, tooltip: TOOLTIP_KEYS.NONE };
    }
  }

  class SubmissionState {
    constructor({ gradingPeriodsEnabled, selectedGradingPeriodID, isAdmin }) {
      this.gradingPeriodsEnabled = gradingPeriodsEnabled;
      this.selectedGradingPeriodID = selectedGradingPeriodID;
      this.isAdmin = isAdmin;
      this.submissionCellMap = {};
      this.submissionMap = {};
    }

    setup(students, assignments) {
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
        this.gradingPeriodsEnabled,
        this.selectedGradingPeriodID,
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
