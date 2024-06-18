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

import LatePolicyApplicator from '../LatePolicyApplicator'

describe('LatePolicyApplicator#processSubmission', () => {
  let assignment
  let latePolicy
  let submission

  test('returns false when submission is not late or missing', () => {
    submission = {late: false, missing: false}
    assignment = {grading_type: 'points', points_possible: 10}
    expect(LatePolicyApplicator.processSubmission(submission, assignment)).toBe(false)
  })

  describe('Missing submissions', () => {
    beforeEach(() => {
      submission = {
        late: false,
        missing: true,
        entered_grade: null,
        entered_score: null,
        grade: null,
        score: null,
      }
      assignment = {grading_type: 'points', points_possible: 10}
      latePolicy = {
        missingSubmissionDeductionEnabled: true,
        missingSubmissionDeduction: 30,
      }
    })

    test('returns true if the score on the missing submission is changed', () => {
      expect(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)).toBe(
        true
      )
    })

    test('returns false if the score on the missing submission is not null', () => {
      submission.score = 5
      expect(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)).toBe(
        false
      )
    })

    test('returns false if the grade on the missing submission is not null', () => {
      submission.grade = '5'
      expect(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)).toBe(
        false
      )
    })

    test('assigns score/grade to the missing submission when missing deduction enabled', () => {
      LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
      expect(submission.score).toBe(7)
      expect(submission.grade).toBe('7')
    })

    test('assigns entered_score/entered_grade when missing deduction enabled', () => {
      LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
      expect(submission.entered_score).toBe(7)
      expect(submission.entered_grade).toBe('7')
    })
  })

  describe('Late submissions', () => {
    beforeEach(() => {
      submission = {late: true, missing: false}
    })

    test('returns false when assignment has no points_possible', () => {
      assignment = {grading_type: 'points', points_possible: null}
      expect(LatePolicyApplicator.processSubmission(submission, assignment)).toBe(false)
    })

    test('returns false when assignment grading_type is "pass_fail"', () => {
      assignment = {grading_type: 'pass_fail', points_possible: 10}
      expect(LatePolicyApplicator.processSubmission(submission, assignment)).toBe(false)
    })

    describe('Hourly late submission deduction', () => {
      beforeEach(() => {
        submission = {
          late: true,
          missing: false,
          entered_score: 10,
          entered_grade: '10',
          score: 10,
          grade: '10',
          seconds_late: 3600,
        }
        assignment = {grading_type: 'points', points_possible: 10}
        latePolicy = {
          lateSubmissionDeduction: 10,
          lateSubmissionDeductionEnabled: true,
          lateSubmissionMinimumPercentEnabled: false,
          lateSubmissionInterval: 'hour',
        }
      })
      ;[undefined, null, ''].forEach(val => {
        test(`returns false when points_deducted changes between "${val}" and 0`, () => {
          latePolicy.lateSubmissionDeduction = 0
          submission.points_deducted = val
          expect(
            LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
          ).toBe(false)
        })
      })

      test('returns false when late submission penalty does not change its values', () => {
        submission.grade = '9'
        submission.score = 9
        submission.points_deducted = 1
        expect(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)).toBe(
          false
        )
      })

      test('returns true when the hourly late submission penalty changes the score on the submission', () => {
        expect(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)).toBe(
          true
        )
      })

      test('assigns points_deducted to the late submission when hourly late penalty enabled', () => {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.points_deducted).toBe(1)
      })

      test('assigned points_deducted is rounded to a precision of 2', () => {
        latePolicy.lateSubmissionDeduction = 2.35
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.points_deducted).toBeCloseTo(0.24, 2)
      })

      test('assigns a pre-deduction entered score/entered grade to the late submission when hourly late penalty enabled', () => {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.entered_score).toBe(10)
        expect(submission.entered_grade).toBe('10')
      })

      test('assigns a post-deduction score/grade to the late submission when hourly late penalty enabled', () => {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.score).toBe(9)
        expect(submission.grade).toBe('9')
      })
    })

    describe('Daily late submission deduction', () => {
      beforeEach(() => {
        submission = {
          late: true,
          missing: false,
          entered_score: 10,
          entered_grade: '10',
          score: 10,
          grade: '10',
          seconds_late: 3600 * 24 * 2,
        }
        assignment = {grading_type: 'points', points_possible: 10}
        latePolicy = {
          lateSubmissionDeduction: 10,
          lateSubmissionDeductionEnabled: true,
          lateSubmissionMinimumPercentEnabled: false,
          lateSubmissionInterval: 'day',
        }
      })

      test('returns true when the daily late submission penalty changes the score on the submission', () => {
        expect(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)).toBe(
          true
        )
      })

      test('assigns points_deducted to the late submission when daily late penalty enabled', () => {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.points_deducted).toBe(2)
      })

      test('assigned points_deducted is rounded to a precision of 2', () => {
        // 2.375 * 2 == 4.75; round(4.75 / 100, 2) == 0.48
        latePolicy.lateSubmissionDeduction = 2.375
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.points_deducted).toBeCloseTo(0.48, 2)
      })

      test('assigns a pre-deduction score/grade to the late submission when daily late penalty enabled', () => {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.entered_score).toBe(10)
        expect(submission.entered_grade).toBe('10')
      })

      test('assigns a post-deduction score/grade to the late submission when daily late penalty enabled', () => {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.score).toBe(8)
        expect(submission.grade).toBe('8')
      })

      test('does not apply late penalty to late but ungraded submission', () => {
        submission = {
          late: true,
          missing: false,
          entered_score: null,
          entered_grade: null,
          score: null,
          grade: null,
          seconds_late: 3600 * 24 * 2,
        }
        expect(submission.score).toBe(null)
      })

      test('does not remove existing late penalty when policy disabled', () => {
        submission.grade = '8.5'
        submission.score = 8.5
        submission.points_deducted = 1.5
        latePolicy.lateSubmissionDeductionEnabled = false
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.score).toBe(8.5)
        expect(submission.grade).toBe('8.5')
      })

      test('applies late penalty minimum when enabled', () => {
        latePolicy.lateSubmissionMinimumPercentEnabled = true
        latePolicy.lateSubmissionMinimumPercent = 90
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.score).toBe(9)
        expect(submission.grade).toBe('9')
      })

      test('applied late penalty does not bring score below 0', () => {
        submission = {
          late: true,
          missing: false,
          entered_score: 3,
          entered_grade: '3',
          score: 3,
          grade: '3',
          seconds_late: 3600 * 24 * 10,
        }
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.score).toBe(0)
        expect(submission.grade).toBe('0')
      })

      test('does not apply late penalty if entered_score <= late penalty minimum', () => {
        submission = {
          late: true,
          missing: false,
          entered_score: 3,
          entered_grade: '3',
          score: 3,
          grade: '3',
          seconds_late: 3600 * 24 * 10,
        }
        latePolicy.lateSubmissionMinimumPercentEnabled = true
        latePolicy.lateSubmissionMinimumPercent = 50
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy)
        expect(submission.score).toBe(3)
        expect(submission.grade).toBe('3')
      })
    })
  })
})
