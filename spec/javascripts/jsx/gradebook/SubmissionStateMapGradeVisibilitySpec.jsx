define([
  'underscore',
  'timezone',
  'jsx/gradebook/SubmissionStateMap'
], (_, tz, SubmissionStateMap) => {
  const student = {
    id: '1',
    group_ids: ['1'],
    sections: ['1']
  };

  const tooltipKeys = {
    NOT_IN_ANY_GP: "not_in_any_grading_period",
    IN_ANOTHER_GP: "in_another_grading_period",
    IN_CLOSED_GP: "in_closed_grading_period",
    NONE: null
  };

  function createMap(opts={}) {
    const defaults = {
      gradingPeriodsEnabled: false,
      selectedGradingPeriodID: '0',
      isAdmin: false,
      gradingPeriods: []
    };

    const params = Object.assign(defaults, opts);
    return new SubmissionStateMap(params);
  }

  function createAndSetupMap(assignment, opts={}) {
    const map = createMap(opts);
    const assignments = {};
    assignments[assignment.id] = assignment;
    map.setup([student], assignments);
    return map;
  }

  function createGradingPeriod(opts={}) {
    const defaults = {
      id: '1',
      is_last: false,
      closed: false
    };

    return Object.assign(defaults, opts);
  }

  function createOverride({ type, id, dueAt }={}) {
    const override = {
      assignment_id: '1',
      due_at: dueAt,
    };

    if (type === 'student') {
      override.student_ids = [id];
    } else if (type === 'section') {
      override.course_section_id = id;
    } else {
      override.group_id = id;
    }

    return override;
  }

  function createAssignment({ dueAt, overrides, gradedButNotAssigned }={}) {
    const assignment = {
      id: '1',
      only_visible_to_overrides: false,
      assignment_visibility: [],
      due_at: null,
      has_overrides: false
    };

    if (dueAt === undefined) {
      assignment.only_visible_to_overrides = true;
    } else {
      assignment.due_at = tz.parse(dueAt);
    }

    if (overrides) {
      assignment.has_overrides = true;
      assignment.overrides = overrides;

      const overrideForStudent = _.any(overrides, function(override) {
        const includesStudent = override.student_ids && _.contains(override.student_ids, student.id);
        const includesSection = _.contains(student.sections, override.course_section_id);
        const includesGroup = _.contains(student.group_ids, override.group_id);
        return includesStudent || includesSection || includesGroup;
      });

      const studentGradedButNotAssigned = gradedButNotAssigned && _.contains(gradedButNotAssigned, student.id);

      if (overrideForStudent || studentGradedButNotAssigned) assignment.assignment_visibility.push(student.id);
    }

    return assignment;
  }

  // TODO: the spec setup above should live in a spec helper -- at the
  // time this is being written a significant amount of work is needed
  // to be able to require javascript files that live in the spec directory

  const OTHER_STUDENT_ID = '2';

  module('SubmissionStateMap with MGP disabled');

  test('submission has grade hidden for an unassigned student with no submission or ungraded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: null });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, { gradingPeriodsEnabled: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an unassigned student with a graded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: null });
    const assignment = createAssignment({ overrides: [override], gradedButNotAssigned: [student.id] });
    const map = createAndSetupMap(assignment, { gradingPeriodsEnabled: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  module('SubmissionStateMap with MGP enabled and all grading periods selected', {
    setup() {
      const closedPeriod = createGradingPeriod({ id: '1', start_date: '2015-07-01', end_date: '2015-07-31', close_date: '2015-08-02', closed: true });
      const openPeriod = createGradingPeriod({ id: '2', start_date: '2015-08-01', end_date: '2015-08-31', close_date: '2015-09-02' });
      const lastPeriod = createGradingPeriod({ id: '3', start_date: '2015-09-01', end_date: '2015-09-30', close_date: '2015-10-02', is_last: true });
      this.DATE_BEFORE_FIRST_PERIOD = '2015-06-15';
      this.DATE_IN_CLOSED_PERIOD = '2015-07-15';
      this.DATE_IN_OPEN_PERIOD = '2015-08-15';
      this.DATE_AFTER_LAST_PERIOD = '2015-10-15';
      const gradingPeriods = [closedPeriod, openPeriod, lastPeriod];
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: '0', gradingPeriods };
    }
  });

  test('submission has grade hidden for an unassigned student with no submission or ungraded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an unassigned student with a graded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override], gradedButNotAssigned: [student.id] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment due in a closed grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_CLOSED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment due in a non-closed grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_OPEN_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment due outside of any grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_AFTER_LAST_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment with no due date', function() {
    const assignment = createAssignment({ dueAt: null });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment due in a closed grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment due in a non-closed grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment due outside of any grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_AFTER_LAST_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with no due date', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: null });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with multiple applicable overrides with the latest due date in a closed grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with multiple applicable overrides with the latest due date in a non-closed grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const mapOptions = Object.assign(this.mapOptions);
    const map = createAndSetupMap(assignment, mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with multiple applicable overrides with the latest due date due outside of any grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_AFTER_LAST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const mapOptions = Object.assign(this.mapOptions);
    const map = createAndSetupMap(assignment, mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with with multiple applicable overrides with at least one override with no due date', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: null });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const mapOptions = Object.assign(this.mapOptions);
    const map = createAndSetupMap(assignment, mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  module('SubmissionStateMap with MGP enabled and a non-closed grading period selected that is not the last grading period', {
    setup() {
      const closedPeriod = createGradingPeriod({ id: '1', start_date: '2015-07-01', end_date: '2015-07-31', close_date: '2015-08-02', closed: true });
      const openPeriod = createGradingPeriod({ id: '2', start_date: '2015-08-01', end_date: '2015-08-31', close_date: '2015-09-02' });
      const lastPeriod = createGradingPeriod({ id: '3', start_date: '2015-09-01', end_date: '2015-09-30', close_date: '2015-10-02', is_last: true });
      this.DATE_BEFORE_FIRST_PERIOD = '2015-06-15';
      this.DATE_IN_CLOSED_PERIOD = '2015-07-15';
      this.DATE_IN_SELECTED_PERIOD = '2015-08-15';
      this.DATE_AFTER_LAST_PERIOD = '2015-10-15';
      const gradingPeriods = [closedPeriod, openPeriod, lastPeriod];
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: openPeriod.id, gradingPeriods };
    }
  });

  test('submission has grade hidden for an unassigned student with no submission or ungraded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an unassigned student with a graded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override], gradedButNotAssigned: [student.id] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_CLOSED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_SELECTED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with assignment with no due date', function() {
    const assignment = createAssignment({ dueAt: null });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with overridden assignment due outside of the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment due in the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_SELECTED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with no due date', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: null });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with multiple applicable overrides with the latest due date outside of the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment with multiple applicable overrides with the latest due date in the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_SELECTED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with with multiple applicable overrides with at least one override with no due date', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_SELECTED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: null });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  module('SubmissionStateMap with MGP enabled and a closed grading period selected that is not the last grading period', {
    setup() {
      const firstClosedPeriod = createGradingPeriod({ id: '1', start_date: '2015-06-01', end_date: '2015-06-30', close_date: '2015-07-02', closed: true });
      const secondClosedPeriod = createGradingPeriod({ id: '2', start_date: '2015-07-01', end_date: '2015-07-31', close_date: '2015-08-02', closed: true });
      const openPeriod = createGradingPeriod({ id: '3', start_date: '2015-08-01', end_date: '2015-08-31', close_date: '2015-09-02'});
      const lastPeriod = createGradingPeriod({ id: '4', start_date: '2015-09-01', end_date: '2015-09-30', close_date: '2015-10-02', is_last: true });
      this.DATE_BEFORE_FIRST_PERIOD = '2015-05-15';
      this.DATE_IN_SELECTED_PERIOD = '2015-07-15';
      this.DATE_IN_OPEN_PERIOD = '2015-08-15';
      this.DATE_AFTER_LAST_PERIOD = '2015-10-15';
      const gradingPeriods = [firstClosedPeriod, secondClosedPeriod, openPeriod, lastPeriod];
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: secondClosedPeriod.id, gradingPeriods };
    }
  });

  test('submission has grade hidden for an unassigned student with no submission or ungraded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an unassigned student with a graded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override], gradedButNotAssigned: [student.id] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_AFTER_LAST_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_SELECTED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with assignment with no due date', function() {
    const assignment = createAssignment({ dueAt: null });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with overridden assignment due outside of the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_AFTER_LAST_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment due in the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_SELECTED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with no due date', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: null });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with multiple applicable overrides with the latest due date outside of the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_AFTER_LAST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment with multiple applicable overrides with the latest due date in the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_SELECTED_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with with multiple applicable overrides with at least one override with no due date', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: null });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_IN_SELECTED_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  module('SubmissionStateMap with MGP enabled and the last grading period selected which is not closed', {
    setup() {
      const closedPeriod = createGradingPeriod({ id: '1', start_date: '2015-07-01', end_date: '2015-07-31', close_date: '2015-08-02', closed: true });
      const openPeriod = createGradingPeriod({ id: '2', start_date: '2015-08-01', end_date: '2015-08-31', close_date: '2015-09-02' });
      const lastPeriod = createGradingPeriod({ id: '3', start_date: '2015-09-01', end_date: '2015-09-30', close_date: '2015-10-02', is_last: true });
      this.DATE_BEFORE_FIRST_PERIOD = '2015-06-15';
      this.DATE_IN_CLOSED_PERIOD = '2015-07-15';
      this.DATE_IN_OPEN_PERIOD = '2015-08-15';
      this.DATE_IN_SELECTED_PERIOD = '2015-09-15';
      this.DATE_AFTER_LAST_PERIOD = '2015-10-15';
      const gradingPeriods = [closedPeriod, openPeriod, lastPeriod];
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: lastPeriod.id, gradingPeriods };
    }
  });

  test('submission has grade hidden for an unassigned student with no submission or ungraded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an unassigned student with a graded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override], gradedButNotAssigned: [student.id] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_CLOSED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_SELECTED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment with no due date', function() {
    const assignment = createAssignment({ dueAt: null });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment due outside of the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment due in the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_SELECTED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with no due date', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: null });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with multiple applicable overrides with the latest due date outside of the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_AFTER_LAST_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment with multiple applicable overrides with the latest due date in the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_SELECTED_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with with multiple applicable overrides with at least one override with no due date', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: null });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_AFTER_LAST_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  module('SubmissionStateMap with MGP enabled and the last grading period selected which is closed', {
    setup() {
      const closedPeriod = createGradingPeriod({ id: '1', start_date: '2015-07-01', end_date: '2015-07-31', close_date: '2015-08-02', closed: true });
      const openPeriod = createGradingPeriod({ id: '2', start_date: '2015-08-01', end_date: '2015-08-31', close_date: '2015-12-25' });
      const lastPeriodAndClosed = createGradingPeriod({ id: '3', start_date: '2015-09-01', end_date: '2015-09-30', close_date: '2015-10-02', is_last: true, closed: true });
      this.DATE_BEFORE_FIRST_PERIOD = '2015-06-15';
      this.DATE_IN_CLOSED_PERIOD = '2015-07-15';
      this.DATE_IN_OPEN_PERIOD = '2015-08-15';
      this.DATE_IN_SELECTED_PERIOD = '2015-09-15';
      this.DATE_AFTER_LAST_PERIOD = '2015-10-15';
      const gradingPeriods = [closedPeriod, openPeriod, lastPeriodAndClosed];
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: lastPeriodAndClosed.id, gradingPeriods };
    }
  });

  test('submission has grade hidden for an unassigned student with no submission or ungraded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an unassigned student with a graded submission', function() {
    const override = createOverride({ type: 'student', id: OTHER_STUDENT_ID, dueAt: this.DATE_IN_OPEN_PERIOD });
    const assignment = createAssignment({ overrides: [override], gradedButNotAssigned: [student.id] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_CLOSED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = createAssignment({ dueAt: this.DATE_IN_SELECTED_PERIOD });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment with no due date', function() {
    const assignment = createAssignment({ dueAt: null });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment due outside of the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment due in the selected grading period', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_SELECTED_PERIOD });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with no due date', function() {
    const override = createOverride({ type: 'student', id: student.id, dueAt: null });
    const assignment = createAssignment({ overrides: [override] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade hidden for an assigned student with overridden assignment with multiple applicable overrides with the latest due date outside of the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_IN_OPEN_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_AFTER_LAST_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with overridden assignment with multiple applicable overrides with the latest due date in the selected grading period', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: this.DATE_IN_CLOSED_PERIOD });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_IN_SELECTED_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_BEFORE_FIRST_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with overridden assignment with with multiple applicable overrides with at least one override with no due date', function() {
    const studentOverride = createOverride({ type: 'student', id: student.id, dueAt: null });
    const sectionOverride = createOverride({ type: 'section', id: student.sections[0], dueAt: this.DATE_AFTER_LAST_PERIOD });
    const groupOverride = createOverride({ type: 'group', id: student.group_ids[0], dueAt: this.DATE_IN_CLOSED_PERIOD });
    const assignment = createAssignment({ overrides: [studentOverride, sectionOverride, groupOverride] });
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });
});
