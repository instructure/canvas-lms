define([
  'underscore',
  'timezone',
  'jsx/gradezilla/SubmissionStateMap'
], (_, tz, SubmissionStateMap) => {
  const student = {
    id: '1',
    group_ids: ['1'],
    sections: ['1']
  };

  function createMap(opts={}) {
    const defaults = {
      gradingPeriodsEnabled: false,
      selectedGradingPeriodID: '0',
      isAdmin: false
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

  // TODO: the spec setup above should live in a spec helper -- at the
  // time this is being written a significant amount of work is needed
  // to be able to require javascript files that live in the spec directory

  QUnit.module('SubmissionStateMap with MGP disabled');

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, { gradingPeriodsEnabled: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for a student with assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: null,
      grading_period_id: null,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, { gradingPeriodsEnabled: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  QUnit.module('SubmissionStateMap with MGP enabled and all grading periods selected', {
    setup() {
      this.DATE_IN_CLOSED_PERIOD = '2015-07-15';
      this.DATE_NOT_IN_CLOSED_PERIOD = '2015-08-15';
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: '0' };
    }
  });

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in a closed grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_CLOSED_PERIOD,
      grading_period_id: '1',
      in_closed_grading_period: true
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment due outside of a closed grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_CLOSED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  QUnit.module('SubmissionStateMap with MGP enabled and a non-closed grading period selected', {
    setup() {
      this.SELECTED_PERIOD_ID = '1';
      this.DATE_IN_SELECTED_PERIOD = '2015-08-15';
      this.DATE_NOT_IN_SELECTED_PERIOD = '2015-10-15';
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: this.SELECTED_PERIOD_ID };
    }
  });

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_SELECTED_PERIOD,
      grading_period_id: this.SELECTED_PERIOD_ID,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  QUnit.module('SubmissionStateMap with MGP enabled and a closed grading period selected', {
    setup() {
      this.SELECTED_PERIOD_ID = '1';
      this.DATE_IN_SELECTED_PERIOD = '2015-07-15';
      this.DATE_NOT_IN_SELECTED_PERIOD = '2015-08-15';
      this.mapOptions = { gradingPeriodsEnabled: true, selectedGradingPeriodID: this.SELECTED_PERIOD_ID };
    }
  });

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_SELECTED_PERIOD,
      grading_period_id: this.SELECTED_PERIOD_ID,
      in_closed_grading_period: true
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });
});
