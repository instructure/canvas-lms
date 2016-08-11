define([
  'underscore',
  'timezone',
  'i18n!gradebook2'
], function(_, tz, I18n) {

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

  function assignedToStudent(assignment, overriddenDate) {
    if (!assignment.only_visible_to_overrides) return true;
    return overriddenDate !== undefined;
  }

  function isAllGradingPeriods(periodId) {
    return periodId === "0";
  }

  function lastGradingPeriodAndDueAtNull(gradingPeriod, dueAt) {
    return gradingPeriod.is_last && dueAt === null;
  }

  function dateIsInGradingPeriod(gradingPeriod, date) {
    if (date === null) return false;
    return tz.parse(gradingPeriod.start_date) < date && date <= tz.parse(gradingPeriod.end_date);
  }

  function addStudentID(student, collection = []) {
    return collection.concat([student.id]);
  }

  function studentIDCollections(students) {
    const sections = {};
    const groups = {};

    students.forEach(function(student) {
      student.sections.forEach(sectionID => sections[sectionID] = addStudentID(student, sections[sectionID]));
      student.group_ids.forEach(groupID => groups[groupID] = addStudentID(student, groups[groupID]));
    });

    return { studentIDsInSections: sections, studentIDsInGroups: groups };
  }

  function studentIDsOnOverride(override, sections, groups) {
    if (override.student_ids) {
      return override.student_ids;
    } else if (override.course_section_id && sections[override.course_section_id]) {
      return sections[override.course_section_id];
    } else if (override.group_id && groups[override.group_id]) {
      return groups[override.group_id];
    } else {
      return [];
    }
  }

  function getLatestDefinedDate(newDate, existingDate) {
    if (existingDate === undefined || newDate === null) {
      return newDate;
    } else if (existingDate !== null && newDate > existingDate) {
      return newDate;
    } else {
      return existingDate;
    }
  }

  function indexOverrides(assignments, students) {
    const { studentIDsInSections, studentIDsInGroups } = studentIDCollections(students);
    const overrides = students.reduce(function(obj, student) {
      obj[student.id] = {};
      return obj;
    }, {});

    _.each(assignments, function(assignment) {
      if (!assignment.has_overrides || !assignment.overrides) return;

      assignment.overrides.forEach(function(override) {
        const studentIDs = studentIDsOnOverride(override, studentIDsInSections, studentIDsInGroups);

        studentIDs.forEach(function(studentID) {
          overrides[studentID] = overrides[studentID] || {};
          const existingDate = overrides[studentID][assignment.id];
          const newDate = tz.parse(override.due_at);
          overrides[studentID][assignment.id] = getLatestDefinedDate(newDate, existingDate);
        });
      });
    });

    return overrides;
  }

  function getGradingPeriodForDueAt(gradingPeriods, dueAt) {
    return _.find(gradingPeriods, function(period) {
      return lastGradingPeriodAndDueAtNull(period, dueAt) ||
             dateIsInGradingPeriod(period, dueAt);
    });
  }

  function cellMapForSubmission(assignment, student, overriddenDate, gradingPeriodsEnabled, selectedGradingPeriodID, gradingPeriods, isAdmin) {
    if (!visibleToStudent(assignment, student)) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NONE };
    } else if (gradingPeriodsEnabled) {
      return cellMappingsForMultipleGradingPeriods(assignment, student, overriddenDate, selectedGradingPeriodID, gradingPeriods, isAdmin);
    } else {
      return { locked: false, hideGrade: false, tooltip: TOOLTIP_KEYS.NONE };
    }
  }

  function cellMappingsForMultipleGradingPeriods(assignment, student, overriddenDate, selectedGradingPeriodID, gradingPeriods, isAdmin) {
    const specificPeriodSelected = !isAllGradingPeriods(selectedGradingPeriodID);
    const effectiveDueAt = overriddenDate === undefined ? assignment.due_at : overriddenDate;
    const gradingPeriodForDueAt = getGradingPeriodForDueAt(gradingPeriods, effectiveDueAt);

    if (specificPeriodSelected && visibleToStudent(assignment, student) && !assignedToStudent(assignment, overriddenDate)) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NOT_IN_ANY_GP };
    } else if (specificPeriodSelected && !gradingPeriodForDueAt) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.NOT_IN_ANY_GP };
    } else if (specificPeriodSelected && selectedGradingPeriodID !== gradingPeriodForDueAt.id) {
      return { locked: true, hideGrade: true, tooltip: TOOLTIP_KEYS.IN_ANOTHER_GP };
    } else if (!isAdmin && (gradingPeriodForDueAt || {}).closed) {
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
      this.overrides = Object.assign(this.overrides, newOverrides);

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
        this.overrides[student.id][assignment.id],
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
