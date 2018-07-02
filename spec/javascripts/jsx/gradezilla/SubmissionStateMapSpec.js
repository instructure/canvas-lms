/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {fromJS} from 'immutable';
import moment from 'moment';
import SubmissionStateMap from 'jsx/gradezilla/SubmissionStateMap';

const studentWithoutSubmission = {
  id: '1',
  group_ids: ['1'],
  sections: ['1']
};

const studentWithSubmission = {
  id: '1',
  group_ids: ['1'],
  sections: ['1'],
  assignment_1: {}
};

const yesterday = moment(new Date()).subtract(1, 'day');
const tomorrow = moment(new Date()).add(1, 'day');

const baseAssignment = fromJS({
  id: '1',
  published: true,
  effectiveDueDates: {1: {due_at: new Date(), grading_period_id: '2', in_closed_grading_period: true}}
})
const unpublishedAssignment = baseAssignment.merge({published: false})
const anonymousMutedAssignment = baseAssignment.merge({
  anonymize_students: true,
  anonymous_grading: true,
  muted: true
})
const moderatedAndGradesUnpublishedAssignment =
  baseAssignment.merge({moderated_grading: true, grades_published: false})
const hiddenFromStudent =
  baseAssignment.merge({only_visible_to_overrides: true, assignment_visibility: []})
const hasGradingPeriodsAssignment = baseAssignment

function createMap (opts = {}) {
  const defaults = {
    hasGradingPeriods: false,
    selectedGradingPeriodID: '0',
    isAdmin: false
  };

  const params = { ...defaults, ...opts };
  return new SubmissionStateMap(params);
}

function createAndSetupMap (assignment, student, opts = {}) {
  const map = createMap(opts);
  const assignments = {};
  assignments[assignment.id] = assignment;
  map.setup([student], assignments);
  return map;
}

QUnit.module('#setSubmissionCellState', function() {
  test('the submission state is locked if assignment is not published', function() {
    const assignment = {
      id: '1',
      published: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, true);
  });

  test('the submission state has hideGrade set if assignment is not published', function() {
    const assignment = {
      id: '1',
      published: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, true);
  });

  test('the submission state is locked if assignment is not visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: []
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, true);
  });

  test('the submission state has hideGrade set if assignment is not visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: []
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, true);
  });

  test('the submission state is not locked if assignment is published and visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, false);
  });

  test('the submission state has hideGrade not set if assignment is published and visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, false);
  });

  test('the submission state is locked when the student is not assigned', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: ['2']
    }
    const map = createAndSetupMap(assignment, studentWithSubmission)
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
    strictEqual(submission.locked, true)
  })

  test('the submission state is not locked if not moderated grading', function() {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, false);
  });

  test('the submission state has hideGrade not set if not moderated grading', function() {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, false);
  });

  test('the submission state is not locked if moderated grading and grades published', function() {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: true
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, false);
  });

  test('the submission state has hideGrade not set if moderated grading and grades published', function() {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: true
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, false);
  });

  test('the submission state is locked if moderated grading and grades not published', function() {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, true);
  });

  test('the submission state has hideGrade not set if moderated grading and grades not published', function() {
    const assignment = {
      id: '1',
      published: true,
      moderated_grading: true,
      grades_published: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, false);
  });

  QUnit.module('when the assignment is anonymous', function(hooks) {
    let assignment

    hooks.beforeEach(() => {
      assignment = { id: '1', published: true, anonymous_grading: true }
    })

    test('the submission state is locked when anonymize_students is true', function() {
      assignment.anonymize_students = true
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
      strictEqual(submission.locked, true)
    })

    test('the submission state is hidden when anonymize_students is true', function() {
      assignment.anonymize_students = true
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
      strictEqual(submission.hideGrade, true)
    })

    test('the submission state is unlocked when the assignment is unmuted', function() {
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
      strictEqual(submission.locked, false)
    })

    test('the submission state is not hidden when the assignment is unmuted', function() {
      const map = createAndSetupMap(assignment, studentWithSubmission)
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
      strictEqual(submission.hideGrade, false)
    })
  })

  QUnit.module('no submission', function() {
    test('the submission object is missing if the assignment is late', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: yesterday } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.missing, true);
    });

    test('the submission object is not missing if the assignment is not late', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: tomorrow } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.missing, false);
    });

    test('the submission object is not missing, if the assignment is not late ' +
      'and there are no due dates', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {}
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.missing, false);
    });

    test('the submission object has seconds_late set to zero', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: new Date() } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.seconds_late, 0);
    });

    test('the submission object has late set to false', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: new Date() } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.late, false);
    });

    test('the submission object has excused set to false', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: new Date() } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.excused, false);
    });
  });

  test('an unpublished assignment is locked and grades are hidden', () => {
    const map = createAndSetupMap(unpublishedAssignment.toJS(), studentWithoutSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: moderatedAndGradesUnpublishedAssignment.get('id')
    })
    deepEqual(submission, {locked: true, hideGrade: true})
  })

  test('a moderated and unpublished grades assignment is locked and grades not hidden when published', () => {
    const map = createAndSetupMap(moderatedAndGradesUnpublishedAssignment.toJS(), studentWithoutSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: moderatedAndGradesUnpublishedAssignment.get('id')
    })
    deepEqual(submission, {locked: true, hideGrade: false})
  })

  test('an assignment that is hidden from the student is locked and grades are hidden', () => {
    const map = createAndSetupMap(hiddenFromStudent.toJS(), studentWithoutSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: hiddenFromStudent.get('id')
    })
    deepEqual(submission, {locked: true, hideGrade: true})
  })

  // TODO: add specs for grading period results GRADE-1276

  test('an assignment that does not fall into any other buckets is unlocked and does not hide grades', () => {
    const map = createAndSetupMap(baseAssignment.toJS(), studentWithoutSubmission)
    const submission = map.getSubmissionState({
      user_id: studentWithoutSubmission.id,
      assignment_id: baseAssignment.get('id')
    })
    deepEqual(submission, {locked: false, hideGrade: false})
  })

  QUnit.module('Order of submission state’s grade visibility and locking.', () => {
    QUnit.module('An assignment that', () => {
      test('is unpublished takes precedence over one that is moderated and has unpublished grades', () => {
        const assignment = moderatedAndGradesUnpublishedAssignment.merge(unpublishedAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission)
        const submission = map.getSubmissionState({user_id: studentWithSubmission.id, assignment_id: assignment.get('id')})
        deepEqual(submission, {locked: true, hideGrade: true})
      })

      test('is anonymously graded and muted takes precedence over one that is moderated and has unpublished grades', () => {
        const assignment = moderatedAndGradesUnpublishedAssignment.merge(anonymousMutedAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission)
        const submission = map.getSubmissionState({user_id: studentWithSubmission.id, assignment_id: assignment.get('id')})
        deepEqual(submission, {locked: true, hideGrade: true})
      })

      test('is moderated and has unpublished grades takes precedence over one that is hidden from the student', () => {
        const assignment = hiddenFromStudent.merge(moderatedAndGradesUnpublishedAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission)
        const submission = map.getSubmissionState({user_id: studentWithSubmission.id, assignment_id: assignment.get('id')})
        deepEqual(submission, {locked: true, hideGrade: false})
      })

      test('is hidden from the student takes precendence over one that has grading periods', () => {
        const assignment = hasGradingPeriodsAssignment.merge(hiddenFromStudent)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission, {hasGradingPeriods: true})
        const submission = map.getSubmissionState({user_id: studentWithSubmission.id, assignment_id: assignment.get('id')})
        deepEqual(submission, {locked: true, hideGrade: true})
      })

      test('has grading periods takes precendence over all other assignments', () => {
        const assignment = hasGradingPeriodsAssignment.merge(baseAssignment)
        const map = createAndSetupMap(assignment.toJS(), studentWithSubmission, {hasGradingPeriods: true})
        const actualSubmissionState = map.getSubmissionState({user_id: studentWithSubmission.id, assignment_id: assignment.get('id')})
        const expectedSubmissionState = {
          locked: true,
          hideGrade: false,
          inClosedGradingPeriod: true,
          inNoGradingPeriod: false,
          inOtherGradingPeriod: false
        }
        deepEqual(actualSubmissionState, expectedSubmissionState)
      })
    })
  })
});
