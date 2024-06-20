/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import * as GradeInputHelper from '../GradeInputHelper'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('GradeInputHelper', () => {
  beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('.isExcused()', () => {
    test('returns true when given "EX"', () => {
      expect(GradeInputHelper.isExcused('EX')).toBe(true)
    })

    test('returns true when given "ex"', () => {
      expect(GradeInputHelper.isExcused('ex')).toBe(true)
    })

    test('returns true when given "EX" with surrounding whitespace', () => {
      expect(GradeInputHelper.isExcused('  EX  ')).toBe(true)
    })

    test('returns false when given "E X"', () => {
      expect(GradeInputHelper.isExcused('E X')).toBe(false)
    })

    test('returns false when given a point value', () => {
      expect(GradeInputHelper.isExcused('7')).toBe(false)
    })

    test('returns false when given a percentage value', () => {
      expect(GradeInputHelper.isExcused('7%')).toBe(false)
    })

    test('returns false when given a letter grade', () => {
      expect(GradeInputHelper.isExcused('A')).toBe(false)
    })

    test('returns false when given an empty string ""', () => {
      expect(GradeInputHelper.isExcused('')).toBe(false)
    })

    test('returns false when given null', () => {
      expect(GradeInputHelper.isExcused(null)).toBe(false)
    })
  })

  describe('.isMissing()', () => {
    test('returns true when given "MI"', () => {
      expect(GradeInputHelper.isMissing('MI')).toBe(true)
    })

    test('returns true when given "mi"', () => {
      expect(GradeInputHelper.isMissing('mi')).toBe(true)
    })

    test('returns true when given "  MI  "', () => {
      expect(GradeInputHelper.isMissing('  MI  ')).toBe(true)
    })

    test('returns false when given "M I"', () => {
      expect(GradeInputHelper.isMissing('M I')).toBe(false)
    })

    test('returns false when given a point value', () => {
      expect(GradeInputHelper.isMissing('7')).toBe(false)
    })

    test('returns false when given a percentage value', () => {
      expect(GradeInputHelper.isMissing('7%')).toBe(false)
    })

    test('returns false when given a letter grade', () => {
      expect(GradeInputHelper.isMissing('A')).toBe(false)
    })

    test('returns false when given an empty string ""', () => {
      expect(GradeInputHelper.isMissing('')).toBe(false)
    })

    test('returns false when given null', () => {
      expect(GradeInputHelper.isMissing(null)).toBe(false)
    })
  })

  describe('.hasGradeChanged()', () => {
    let options
    let pendingGradeInfo
    let submission

    function hasGradeChanged() {
      return GradeInputHelper.hasGradeChanged(submission, pendingGradeInfo, options)
    }

    beforeEach(() => {
      options = {
        enterGradesAs: 'points',
        gradingScheme: [
          ['A', 0.9],
          ['B', 0.8],
          ['C', 0.7],
          ['D', 0.6],
          ['F', 0.5],
        ],
        pointsPossible: 10,
      }
      // cleared grade info
      pendingGradeInfo = {
        enteredAs: null,
        excused: false,
        late_policy_status: null,
        grade: null,
        score: null,
        valid: true,
      }
      submission = {
        enteredGrade: 'A',
        enteredScore: 10,
        excused: false,
        grade: 'B',
        late_policy_status: null,
      }
    })

    test('returns true when the pending grade is invalid', () => {
      Object.assign(pendingGradeInfo, {grade: 'invalid', valid: false})
      expect(hasGradeChanged()).toBe(true)
    })

    test('returns true when the submission is becoming excused', () => {
      Object.assign(pendingGradeInfo, {enteredAs: 'excused', excused: true})
      expect(hasGradeChanged()).toBe(true)
    })

    test('returns true when the submission is becoming unexcused', () => {
      submission = {enteredGrade: null, enteredScore: null, excused: true, grade: null}
      expect(hasGradeChanged()).toBe(true)
    })

    test('returns true when the submission is becoming missing', () => {
      Object.assign(pendingGradeInfo, {late_policy_status: 'missing'})
      submission = {
        enteredGrade: null,
        enteredScore: null,
        excused: false,
        late_policy_status: null,
        grade: null,
      }
      expect(hasGradeChanged()).toBe(true)
    })

    test('returns false when the submission is already missing', () => {
      Object.assign(pendingGradeInfo, {late_policy_status: 'missing'})
      submission = {
        enteredGrade: null,
        enteredScore: null,
        excused: false,
        late_policy_status: 'missing',
        grade: null,
      }
      expect(hasGradeChanged()).toBe(false)
    })

    describe('when the pending grade is entered as "points"', () => {
      beforeEach(() => {
        options.enterGradesAs = 'points'
        Object.assign(pendingGradeInfo, {enteredAs: 'points', grade: 'A', score: 10})
      })

      test('returns false when the pending score matches the entered score', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      test('returns true when the pending score does not match the entered score', () => {
        pendingGradeInfo.score = 9.9
        expect(hasGradeChanged()).toBe(true)
      })
    })

    describe('when the pending grade is entered as "percent"', () => {
      beforeEach(() => {
        options.enterGradesAs = 'percent'
        Object.assign(pendingGradeInfo, {enteredAs: 'percent', grade: 'A', score: 10})
      })

      test('returns false when the pending score matches the entered score', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      test('returns true when the pending score does not match the entered score', () => {
        pendingGradeInfo.score = 9.9
        expect(hasGradeChanged()).toBe(true)
      })
    })

    describe('when the pending grade is entered as "gradingScheme"', () => {
      beforeEach(() => {
        options.enterGradesAs = 'gradingScheme'
        Object.assign(pendingGradeInfo, {enteredAs: 'gradingScheme', grade: 'A', score: 10})
      })

      test('returns false when the pending grade matches the submission grade', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      test('returns false when the pending grade matches only the submission grade', () => {
        pendingGradeInfo.score = 9.1
        expect(hasGradeChanged()).toBe(false)
      })

      test('returns true when the pending grade does not match the submission grade', () => {
        Object.assign(pendingGradeInfo, {grade: 'B', score: 8.9})
        expect(hasGradeChanged()).toBe(true)
      })
    })

    describe('when the pending grade is entered as "passFail"', () => {
      beforeEach(() => {
        options.enterGradesAs = 'passFail'
        Object.assign(pendingGradeInfo, {enteredAs: 'passFail', grade: 'complete', score: 10})
        Object.assign(submission, {enteredGrade: 'complete', grade: 'complete'})
      })

      describe('when the assignment is out of zero points', () => {
        beforeEach(() => {
          options.pointsPossible = 0
          pendingGradeInfo.score = 0
          submission.score = 0
        })

        test('returns false when the pending grade matches the submission grade', () => {
          expect(hasGradeChanged()).toBe(false)
        })

        test('returns true when the pending grade differs from the submission grade', () => {
          pendingGradeInfo.grade = 'incomplete'
          expect(hasGradeChanged()).toBe(true)
        })
      })

      test('returns false when the pending score matches the submission score', () => {
        expect(hasGradeChanged()).toBe(false)
      })

      test('returns true when the pending score differs from the submission score', () => {
        pendingGradeInfo.score = 0
        expect(hasGradeChanged()).toBe(true)
      })
    })
  })

  describe('.parseTextValue()', () => {
    let options

    function parseTextValue(value) {
      return GradeInputHelper.parseTextValue(value, options)
    }

    describe('when the "enter grades as" setting is "points"', () => {
      beforeEach(() => {
        options = {
          enterGradesAs: 'points',
          gradingScheme: [
            ['A', 0.9],
            ['B', 0.8],
            ['C', 0.7],
            ['D', 0.6],
            ['F', 0.5],
          ],
          pointsPossible: 10,
        }
      })

      test('stringifies the value for grade when given an integer', () => {
        expect(parseTextValue(8).grade).toBe('8')
      })

      test('sets the grade to the value when given a stringified integer', () => {
        expect(parseTextValue('8').grade).toBe('8')
      })

      test('ignores whitespace from the given value', () => {
        expect(parseTextValue(' 8 ').grade).toBe('8')
      })

      test('stringifies the value for grade when given a decimal', () => {
        expect(parseTextValue(8.34).grade).toBe('8.34')
      })

      test('sets the grade to the value when given a stringified decimal', () => {
        expect(parseTextValue('8.34').grade).toBe('8.34')
      })

      test('rounds points to 15 decimal places', () => {
        expect(parseTextValue('8.12345678901234567890').grade).toBe('8.123456789012346')
      })

      test('converts an integer percentage value to points for the grade', () => {
        expect(parseTextValue('80%').grade).toBe('8')
      })

      test('converts a decimal percentage value to points for the grade', () => {
        expect(parseTextValue('83.4%').grade).toBe('8.34')
      })

      test('rounds a converted percentage grade to 15 decimal places', () => {
        expect(parseTextValue('83.12345678901234567890%').grade).toBe('8.312345678901234')
      })

      test('converts percentages using the "％" symbol', () => {
        expect(parseTextValue('83.35％').grade).toBe('8.335')
      })

      test('converts percentages using the "﹪" symbol', () => {
        expect(parseTextValue('83.35﹪').grade).toBe('8.335')
      })

      test('converts percentages using the "٪" symbol', () => {
        expect(parseTextValue('83.35٪').grade).toBe('8.335')
      })

      test('sets the grade to the numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').grade).toBe('3')
      })

      test('sets the grade using the matching scheme key when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').grade).toBe('8.9')
      })

      test('sets the grade to the given points when given no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('8.3').grade).toBe('8.3')
      })

      test('sets the grade to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('83.45%').grade).toBe('0')
      })

      test('sets the grade to zero when given zero', () => {
        expect(parseTextValue(0).grade).toBe('0')
      })

      test('converts a grading scheme value to points for the grade', () => {
        expect(parseTextValue('B').grade).toBe('8.9')
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        expect(parseTextValue(' B ').grade).toBe('8.9')
      })

      test('sets the grade to the given non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').grade).toBe('B-')
      })

      test('sets the grade to null when the value is blank', () => {
        expect(parseTextValue('  ').grade).toBeNull()
      })

      test('sets the grade to null when the value is null', () => {
        expect(parseTextValue(null).grade).toBeNull()
      })

      test('sets the grade to the given non-numerical string when given no grading scheme', () => {
        options.gradingScheme = null
        expect(parseTextValue('B').grade).toBe('B')
      })

      test('sets the score to the value when given an integer', () => {
        expect(parseTextValue(8).score).toBe(8)
      })

      test('parses the value for score when given a stringified integer', () => {
        expect(parseTextValue('8').score).toBe(8)
      })

      test('sets the score to the value when given a decimal', () => {
        expect(parseTextValue(8.34).score).toBe(8.34)
      })

      test('parses the value for score when given a stringified decimal', () => {
        expect(parseTextValue('8.34').score).toBe(8.34)
      })

      test('rounds points to 15 decimal places (2)', () => {
        expect(parseTextValue('8.12345678901234567890').score).toBe(8.123456789012346)
      })

      test('converts an integer percentage value to points for the score', () => {
        expect(parseTextValue('80%').score).toBe(8)
      })

      test('converts a decimal percentage value to points for the score', () => {
        expect(parseTextValue('83.4%').score).toBe(8.34)
      })

      test('converts a percentage using alternate points possible', () => {
        options.pointsPossible = 15
        expect(parseTextValue('80%').score).toBe(12)
      })

      test('rounds a converted percentage score to 15 decimal places', () => {
        expect(parseTextValue('83.12345678901234567890%').score).toBe(8.312345678901234)
      })

      test('converts percentages using the "％" symbol (1)', () => {
        expect(parseTextValue('83.35％').score).toBe(8.335)
      })

      test('converts percentages using the "﹪" symbol (2)', () => {
        expect(parseTextValue('83.35﹪').score).toBe(8.335)
      })

      test('converts percentages using the "٪" symbol (3)', () => {
        expect(parseTextValue('83.35٪').score).toBe(8.335)
      })

      test('sets the score to the numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').score).toBe(3)
      })

      test('sets the score using the matching scheme key when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').score).toBe(8.9)
      })

      test('sets the score to the given points when given no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('8.3').score).toBe(8.3)
      })

      test('sets the score to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('83.45%').score).toBe(0)
      })

      test('sets the score to zero when given zero', () => {
        expect(parseTextValue(0).score).toBe(0)
      })

      test('converts a grading scheme value to points for the score', () => {
        expect(parseTextValue('B').score).toBe(8.9)
      })

      test('converts a grading scheme value using alternate points possible', () => {
        options.pointsPossible = 15
        expect(parseTextValue('B').score).toBe(13.35)
      })

      test('ignores whitespace from the given value when setting the grade (2)', () => {
        expect(parseTextValue(' B ').score).toBe(8.9)
      })

      test('sets a grading scheme score to zero when given 0 points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('B').score).toBe(0)
      })

      test('sets a grading scheme score to zero when given null points possible', () => {
        options.pointsPossible = null
        expect(parseTextValue('B').score).toBe(0)
      })

      test('sets the score to null when given a non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').score).toBeNull()
      })

      test('sets the score to null when given no grading scheme for a non-numerical string', () => {
        options.gradingScheme = null
        expect(parseTextValue('B').score).toBeNull()
      })

      test('sets the score to null when the value is blank', () => {
        expect(parseTextValue('  ').score).toBeNull()
      })

      test('sets the grade to null when the value is "EX"', () => {
        expect(parseTextValue('EX').grade).toBeNull()
      })

      test('sets the score to null when the value is "EX"', () => {
        expect(parseTextValue('EX').score).toBeNull()
      })

      test('ignores whitespace around the excused value "EX"', () => {
        expect(parseTextValue(' EX ').excused).toBe(true)
      })

      test('sets excused to true when the value is "EX"', () => {
        expect(parseTextValue('EX').excused).toBe(true)
      })

      test('sets excused to false for any other value', () => {
        expect(parseTextValue('E X').excused).toBe(false)
      })

      test('sets late_policy_status to "missing" when the value is "MI"', () => {
        expect(parseTextValue('MI').late_policy_status).toBe('missing')
      })

      test('sets late_policy_status to null for any other value', () => {
        expect(parseTextValue('8.34').late_policy_status).toBeNull()
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        expect(parseTextValue('EX').enteredAs).toBe('excused')
      })

      test('sets "enteredAs" to "points" when given points', () => {
        expect(parseTextValue('8.34').enteredAs).toBe('points')
      })

      test('sets "enteredAs" to "percent" when given a percentage', () => {
        expect(parseTextValue('83.45%').enteredAs).toBe('percent')
      })

      test('sets "enteredAs" to "gradingScheme" when given a grading scheme key', () => {
        expect(parseTextValue('B').enteredAs).toBe('gradingScheme')
      })

      test('sets "enteredAs" to "points" when given a numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').enteredAs).toBe('points')
      })

      test('sets "enteredAs" to "gradingScheme" when given a percentage value which matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').enteredAs).toBe('gradingScheme')
      })

      test('sets "enteredAs" to null when given a non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').enteredAs).toBeNull()
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        expect(parseTextValue('').enteredAs).toBeNull()
      })

      test('sets "valid" to true when the grade is a valid point value', () => {
        expect(parseTextValue('8.34').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is a valid percentage', () => {
        expect(parseTextValue('83.4%').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is a valid grading scheme key', () => {
        expect(parseTextValue('B').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        expect(parseTextValue('').valid).toBe(true)
      })

      test('sets "valid" to true when the value is "EX"', () => {
        expect(parseTextValue('EX').valid).toBe(true)
      })

      test('sets "valid" to true when the value is "MI"', () => {
        expect(parseTextValue('MI').valid).toBe(true)
      })

      test('sets "valid" to false when given non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').valid).toBe(false)
      })
    })

    describe('when the "enter grades as" setting is "percent"', () => {
      beforeEach(() => {
        options = {
          enterGradesAs: 'percent',
          gradingScheme: [
            ['A', 0.9],
            ['B', 0.8],
            ['C', 0.7],
            ['D', 0.6],
            ['F', 0.5],
          ],
          pointsPossible: 10,
        }
      })

      test('stringifies the value for grade when given an integer', () => {
        expect(parseTextValue(8).grade).toBe('8%')
      })

      test('sets the grade to the value when given a stringified integer', () => {
        expect(parseTextValue('8').grade).toBe('8%')
      })

      test('ignores whitespace from the given value', () => {
        expect(parseTextValue(' 8 ').grade).toBe('8%')
      })

      test('stringifies the value for grade when given a decimal', () => {
        expect(parseTextValue(8.34).grade).toBe('8.34%')
      })

      test('sets the grade to the value when given a stringified decimal', () => {
        expect(parseTextValue('8.34').grade).toBe('8.34%')
      })

      test('rounds points to 15 decimal places', () => {
        expect(parseTextValue('8.12345678901234567890').grade).toBe('8.123456789012346%')
      })

      test('uses the given integer percentage value for the grade', () => {
        expect(parseTextValue('8%').grade).toBe('8%')
      })

      test('uses the given decimal percentage value for the grade', () => {
        expect(parseTextValue('8.34%').grade).toBe('8.34%')
      })

      test('rounds a converted percentage grade to 15 decimal places', () => {
        expect(parseTextValue('83.12345678901234567890%').grade).toBe('83.12345678901235%')
      })

      test('converts percentages using the "％" symbol', () => {
        expect(parseTextValue('83.35％').grade).toBe('83.35%')
      })

      test('converts percentages using the "﹪" symbol', () => {
        expect(parseTextValue('83.35﹪').grade).toBe('83.35%')
      })

      test('converts percentages using the "٪" symbol', () => {
        expect(parseTextValue('83.35٪').grade).toBe('83.35%')
      })

      test('sets the grade to the numerical value as a percentage even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').grade).toBe('3%')
      })

      test('sets the grade to the percentage value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').grade).toBe('85%')
      })

      test('sets the score to the given points when given no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('8.3').grade).toBe('8.3%')
      })

      test('sets the grade to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('83.45%').grade).toBe('0%')
      })

      test('sets the grade to zero when given zero', () => {
        expect(parseTextValue(0).grade).toBe('0%')
      })

      test('converts a grading scheme value to a percentage for the grade', () => {
        expect(parseTextValue('B').grade).toBe('89%')
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        expect(parseTextValue(' B ').grade).toBe('89%')
      })

      test('sets the grade to the given non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').grade).toBe('B-')
      })

      test('sets the grade to null when the value is blank', () => {
        expect(parseTextValue('  ').grade).toBeNull()
      })

      test('sets the grade to the given non-numerical string when given no grading scheme', () => {
        options.gradingScheme = null
        expect(parseTextValue('B').grade).toBe('B')
      })

      test('sets the score to the result of the value divided by points possible when given an integer', () => {
        expect(parseTextValue(8).score).toBe(0.8)
      })

      test('parses the value for score when given a stringified integer', () => {
        expect(parseTextValue('8').score).toBe(0.8)
      })

      test('sets the score to the value when given a decimal', () => {
        expect(parseTextValue(8.3).score).toBe(0.83)
      })

      test('parses the value for score when given a stringified decimal', () => {
        expect(parseTextValue('8.3').score).toBe(0.83)
      })

      test('rounds points to 15 decimal places (2)', () => {
        expect(parseTextValue('8.12345678901234567890').score).toBe(0.812345678901235)
      })

      test('preserves the precision of a converted point score', () => {
        // 83.543 / 100 * 10 (points possible) === 8.354300000000002 in JavaScript
        expect(parseTextValue(83.543).score).toBe(8.3543)
      })

      test('preserves a precision arbitrarily longer than the percentage grade precision', () => {
        options.pointsPossible = 9.5
        expect(parseTextValue('55').score).toBe(5.225)
      })

      test('converts an integer percentage value to points for the score', () => {
        expect(parseTextValue('80%').score).toBe(8)
      })

      test('converts a decimal percentage value to points for the score', () => {
        expect(parseTextValue('83.4%').score).toBe(8.34)
      })

      test('converts a percentage using alternate points possible', () => {
        options.pointsPossible = 15
        expect(parseTextValue('80%').score).toBe(12)
      })

      test('rounds a converted percentage score to 15 decimal places', () => {
        expect(parseTextValue('83.12345678901234567890%').score).toBe(8.312345678901234)
      })

      test('converts percentages using the "％" symbol (1)', () => {
        expect(parseTextValue('83.35％').score).toBe(8.335)
      })

      test('converts percentages using the "﹪" symbol (2)', () => {
        expect(parseTextValue('83.35﹪').score).toBe(8.335)
      })

      test('converts percentages using the "٪" symbol (3)', () => {
        expect(parseTextValue('83.35٪').score).toBe(8.335)
      })

      test('sets the score to the numerical value as a percentage even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').score).toBe(0.3)
      })

      test('sets the score to the percentage value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').score).toBe(8.5)
      })

      test('parses a point value as a percentage for score when given no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('8.3').score).toBe(8.3)
      })

      test('sets the score to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('83.45%').score).toBe(0)
      })

      test('sets the score to zero when given zero', () => {
        expect(parseTextValue(0).score).toBe(0)
      })

      test('converts a grading scheme value to points for the score', () => {
        expect(parseTextValue('B').score).toBe(8.9)
      })

      test('converts a grading scheme value using alternate points possible', () => {
        options.pointsPossible = 15
        expect(parseTextValue('B').score).toBe(13.35)
      })

      test('ignores whitespace from the given value when setting the grade (2)', () => {
        expect(parseTextValue(' B ').score).toBe(8.9)
      })

      test('sets a grading scheme score to zero when given 0 points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('B').score).toBe(0)
      })

      test('sets a grading scheme score to zero when given null points possible', () => {
        options.pointsPossible = null
        expect(parseTextValue('B').score).toBe(0)
      })

      test('sets the score to null when given a non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').score).toBeNull()
      })

      test('sets the score to null when given no grading scheme for a non-numerical string', () => {
        options.gradingScheme = null
        expect(parseTextValue('B').score).toBeNull()
      })

      test('sets the score to null when the value is blank', () => {
        expect(parseTextValue('  ').score).toBeNull()
      })

      test('sets the grade to null when the value is "EX"', () => {
        expect(parseTextValue('EX').grade).toBeNull()
      })

      test('sets the score to null when the value is "EX"', () => {
        expect(parseTextValue('EX').score).toBeNull()
      })

      test('sets excused to true when the value is "EX"', () => {
        expect(parseTextValue('EX').excused).toBe(true)
      })

      test('sets excused to false for any other value', () => {
        expect(parseTextValue('E X').excused).toBe(false)
      })

      test('sets late_policy_status to "missing" when the value is "MI"', () => {
        expect(parseTextValue('MI').late_policy_status).toBe('missing')
      })

      test('sets late_policy_status to null for any other value', () => {
        expect(parseTextValue('83.45%').late_policy_status).toBeNull()
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        expect(parseTextValue('EX').enteredAs).toBe('excused')
      })

      test('sets "enteredAs" to "percent" when given points', () => {
        expect(parseTextValue('8.34').enteredAs).toBe('percent')
      })

      test('sets "enteredAs" to "percent" when given a percentage', () => {
        expect(parseTextValue('83.45%').enteredAs).toBe('percent')
      })

      test('sets "enteredAs" to "gradingScheme" when given a grading scheme key', () => {
        expect(parseTextValue('B').enteredAs).toBe('gradingScheme')
      })

      test('sets "enteredAs" to "percent" when given a numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').enteredAs).toBe('percent')
      })

      test('sets "enteredAs" to "percent" when given a percentage value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').enteredAs).toBe('percent')
      })

      test('sets "enteredAs" to null when given a non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').enteredAs).toBeNull()
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        expect(parseTextValue('').enteredAs).toBeNull()
      })

      test('sets "valid" to true when the grade is a valid point value', () => {
        expect(parseTextValue('8.34').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is a valid percentage', () => {
        expect(parseTextValue('83.4%').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is a valid grading scheme key', () => {
        expect(parseTextValue('B').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        expect(parseTextValue('').valid).toBe(true)
      })

      test('sets "valid" to true when the value is "EX"', () => {
        expect(parseTextValue('EX').valid).toBe(true)
      })

      test('sets "valid" to true when the value is "MI"', () => {
        expect(parseTextValue('MI').valid).toBe(true)
      })

      test('sets "valid" to false when given non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').valid).toBe(false)
      })
    })

    describe('when the "enter grades as" setting is "gradingScheme"', () => {
      beforeEach(() => {
        options = {
          enterGradesAs: 'gradingScheme',
          gradingScheme: [
            ['A', 0.9],
            ['B', 0.8],
            ['C', 0.7],
            ['D', 0.6],
            ['F', 0.5],
          ],
          pointsPossible: 10,
        }
      })

      test('sets the grade to the matching scheme key when given an integer', () => {
        expect(parseTextValue('B').grade).toBe('B')
      })

      test('uses the exact scheme key when matching with different case', () => {
        expect(parseTextValue('b').grade).toBe('B')
      })

      test('sets the grade to the matching scheme key when given an integer (2)', () => {
        expect(parseTextValue(8).grade).toBe('B')
      })

      test('sets the grade to the matching scheme key when given a stringified integer', () => {
        expect(parseTextValue('8').grade).toBe('B')
      })

      test('sets the grade to the matching scheme key when given a decimal', () => {
        expect(parseTextValue(8.34).grade).toBe('B')
      })

      test('sets the grade to the matching scheme key when given a stringified decimal', () => {
        expect(parseTextValue('8.34').grade).toBe('B')
      })

      test('uses the given percentage value to match a scheme value for the grade', () => {
        expect(parseTextValue('83.45%').grade).toBe('B')
      })

      test('converts percentages using the "％" symbol', () => {
        expect(parseTextValue('83.35％').grade).toBe('B')
      })

      test('converts percentages using the "﹪" symbol', () => {
        expect(parseTextValue('83.35﹪').grade).toBe('B')
      })

      test('converts percentages using the "٪" symbol', () => {
        expect(parseTextValue('83.35٪').grade).toBe('B')
      })

      test('sets the grade to the matching scheme key when given a numerical scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').grade).toBe('3.0')
      })

      test('sets the grade to the matching scheme key when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('95%').grade).toBe('95%')
      })

      test('sets the grade to the lowest scheme value when given a point value and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('8.34').grade).toBe('F')
      })

      test('sets the grade to the lowest scheme value when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('83.45%').grade).toBe('F')
      })

      test('sets the grade to the given scheme value even when given no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('B').grade).toBe('B')
      })

      test('sets the to the lowest scheme value when given zero', () => {
        expect(parseTextValue(0).grade).toBe('F')
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        expect(parseTextValue(' B ').grade).toBe('B')
      })

      test('sets the grade to the given non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').grade).toBe('B-')
      })

      test('sets the grade to null when the value is blank', () => {
        expect(parseTextValue('  ').grade).toBeNull()
      })

      test('sets the grade to the given non-numerical string when given no grading scheme', () => {
        options.gradingScheme = null
        expect(parseTextValue('B').grade).toBe('B')
      })

      test('sets the score to the matching scheme value when given a scheme key', () => {
        expect(parseTextValue('B').score).toBe(8.9)
      })

      test('sets the score using alternate points possible', () => {
        options.pointsPossible = 15
        expect(parseTextValue('B').score).toBe(13.35)
      })

      test('sets the score to the value when given an integer', () => {
        expect(parseTextValue(8).score).toBe(8)
      })

      test('parses the value for score when given a stringified integer', () => {
        expect(parseTextValue('8').score).toBe(8)
      })

      test('sets the score to the value when given a decimal', () => {
        expect(parseTextValue(8.34).score).toBe(8.34)
      })

      test('parses the value for score when given a stringified decimal', () => {
        expect(parseTextValue('8.34').score).toBe(8.34)
      })

      test('rounds points to 15 decimal places', () => {
        expect(parseTextValue('8.12345678901234567890').score).toBe(8.123456789012346)
      })

      test('preserves the precision of a given point score', () => {
        // 8.536 / 10 (points possible) * 100 === 8.535999999999998 in JavaScript
        expect(parseTextValue(8.536).score).toBe(8.536)
      })

      test('converts an integer percentage value to points for the score', () => {
        expect(parseTextValue('80%').score).toBe(8)
      })

      test('converts a decimal percentage value to points for the score', () => {
        expect(parseTextValue('83.4%').score).toBe(8.34)
      })

      test('rounds a converted percentage score to 15 decimal places', () => {
        expect(parseTextValue('83.12345678901234567890%').score).toBe(8.312345678901234)
      })

      test('converts percentages using the "％" symbol (1)', () => {
        expect(parseTextValue('83.35％').score).toBe(8.335)
      })

      test('converts percentages using the "﹪" symbol (2)', () => {
        expect(parseTextValue('83.35﹪').score).toBe(8.335)
      })

      test('converts percentages using the "٪" symbol (3)', () => {
        expect(parseTextValue('83.35٪').score).toBe(8.335)
      })

      test('sets the score to the matching scheme value when given a numerical scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').score).toBe(8.9)
      })

      test('sets the score to the matching scheme value when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').score).toBe(8.9)
      })

      test('sets the score to the value when given a point value and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('8.34').score).toBe(8.34)
      })

      test('sets the score to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('83.45%').score).toBe(0)
      })

      test('sets the score to zero when given a grading scheme key and 0 points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('B').score).toBe(0)
      })

      test('sets the score to zero when given a grading scheme key and null points possible', () => {
        options.pointsPossible = null
        expect(parseTextValue('B').score).toBe(0)
      })

      test('sets the score to zero when given zero', () => {
        expect(parseTextValue(0).score).toBe(0)
      })

      test('sets the score to null when given a non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').score).toBeNull()
      })

      test('sets the score to null when given no grading scheme for a non-numerical string', () => {
        options.gradingScheme = null
        expect(parseTextValue('B').score).toBeNull()
      })

      test('sets the score to null when the value is blank', () => {
        expect(parseTextValue('  ').score).toBeNull()
      })

      test('sets the grade to null when the value is "EX"', () => {
        expect(parseTextValue('EX').grade).toBeNull()
      })

      test('sets the score to null when the value is "EX"', () => {
        expect(parseTextValue('EX').score).toBeNull()
      })

      test('ignores whitespace around the excused value "EX"', () => {
        expect(parseTextValue(' EX ').excused).toBe(true)
      })

      test('sets excused to true when the value is "EX"', () => {
        expect(parseTextValue('EX').excused).toBe(true)
      })

      test('sets excused to false for any other value', () => {
        expect(parseTextValue('E X').excused).toBe(false)
      })

      test('sets late_policy_status to "missing" when the value is "MI"', () => {
        expect(parseTextValue('MI').late_policy_status).toBe('missing')
      })

      test('sets late_policy_status to null for any other value', () => {
        expect(parseTextValue('complete').late_policy_status).toBeNull()
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        expect(parseTextValue('EX').enteredAs).toBe('excused')
      })

      test('sets "enteredAs" to "points" when given points', () => {
        expect(parseTextValue('8.34').enteredAs).toBe('points')
      })

      test('sets "enteredAs" to "percent" when given a percentage', () => {
        expect(parseTextValue('83.45%').enteredAs).toBe('percent')
      })

      test('sets "enteredAs" to "gradingScheme" when given a grading scheme key', () => {
        expect(parseTextValue('B').enteredAs).toBe('gradingScheme')
      })

      test('sets "enteredAs" to "gradingScheme" when given a numerical value which matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5],
        ]
        expect(parseTextValue('3.0').enteredAs).toBe('gradingScheme')
      })

      test('sets "enteredAs" to "gradingScheme" when given a percentage value which matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5],
        ]
        expect(parseTextValue('85%').enteredAs).toBe('gradingScheme')
      })

      test('sets "enteredAs" to null when given a non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').enteredAs).toBeNull()
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        expect(parseTextValue('').enteredAs).toBeNull()
      })

      test('sets "valid" to true when the grade is a valid point value', () => {
        expect(parseTextValue('8.34').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is a valid percentage', () => {
        expect(parseTextValue('83.4%').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is a valid grading scheme key', () => {
        expect(parseTextValue('B').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        expect(parseTextValue('').valid).toBe(true)
      })

      test('sets "valid" to true when the value is "EX"', () => {
        expect(parseTextValue('EX').valid).toBe(true)
      })

      test('sets "valid" to true when the value is "MI"', () => {
        expect(parseTextValue('MI').valid).toBe(true)
      })

      test('sets "valid" to false when given non-numerical string not in the grading scheme', () => {
        expect(parseTextValue('B-').valid).toBe(false)
      })
    })

    describe('when the "enter grades as" setting is "passFail"', () => {
      beforeEach(() => {
        options = {
          enterGradesAs: 'passFail',
          pointsPossible: 10,
        }
      })

      test('sets the grade to "complete" when given "complete"', () => {
        expect(parseTextValue('complete').grade).toBe('complete')
      })

      test('ignores case for "complete" value', () => {
        expect(parseTextValue('COMplete').grade).toBe('complete')
      })

      test('ignores whitespace for "complete" value', () => {
        expect(parseTextValue(' complete ').grade).toBe('complete')
      })

      test('sets the grade to "incomplete" when given "incomplete"', () => {
        expect(parseTextValue('incomplete').grade).toBe('incomplete')
      })

      test('ignores case for "incomplete" value', () => {
        expect(parseTextValue('INComplete').grade).toBe('incomplete')
      })

      test('ignores whitespace for "incomplete" value', () => {
        expect(parseTextValue(' incomplete ').grade).toBe('incomplete')
      })

      test('sets the grade to null when the value is blank', () => {
        expect(parseTextValue('  ').grade).toBeNull()
      })

      test('sets the score to the points possible when given "complete"', () => {
        expect(parseTextValue('complete').score).toBe(10)
      })

      test('sets the score to zero when given "complete" and no points possible', () => {
        options.pointsPossible = 0
        expect(parseTextValue('complete').score).toBe(0)
      })

      test('sets the score to zero when given "complete" and null points possible', () => {
        options.pointsPossible = null
        expect(parseTextValue('complete').score).toBe(0)
      })

      test('sets the score to zero when given "incomplete"', () => {
        expect(parseTextValue('incomplete').score).toBe(0)
      })

      test('sets the score to null when the value is blank', () => {
        expect(parseTextValue('  ').score).toBeNull()
      })

      test('sets the grade to null when the value is "EX"', () => {
        expect(parseTextValue('EX').grade).toBeNull()
      })

      test('sets the score to null when the value is "EX"', () => {
        expect(parseTextValue('EX').score).toBeNull()
      })

      test('ignores whitespace around the excused value "EX"', () => {
        expect(parseTextValue(' EX ').excused).toBe(true)
      })

      test('sets excused to true when the value is "EX"', () => {
        expect(parseTextValue('EX').excused).toBe(true)
      })

      test('sets excused to false when the value is "complete"', () => {
        expect(parseTextValue('complete').excused).toBe(false)
      })

      test('sets excused to false when the value is "incomplete"', () => {
        expect(parseTextValue('incomplete').excused).toBe(false)
      })

      test('sets excused to false for invalid values', () => {
        expect(parseTextValue('E X').excused).toBe(false)
      })

      test('sets late_policy_status to "missing" when the value is "MI"', () => {
        expect(parseTextValue('MI').late_policy_status).toBe('missing')
      })

      test('sets late_policy_status to null for any other value', () => {
        expect(parseTextValue('complete').late_policy_status).toBeNull()
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        expect(parseTextValue('EX').enteredAs).toBe('excused')
      })

      test('sets "enteredAs" to "passFail" when given "complete"', () => {
        expect(parseTextValue('complete').enteredAs).toBe('passFail')
      })

      test('sets "enteredAs" to "passFail" when given "incomplete"', () => {
        expect(parseTextValue('incomplete').enteredAs).toBe('passFail')
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        expect(parseTextValue('').enteredAs).toBeNull()
      })

      test('sets "enteredAs" to null when given any other value', () => {
        expect(parseTextValue('unknown').enteredAs).toBeNull()
      })

      test('sets "valid" to true when given "complete"', () => {
        expect(parseTextValue('complete').valid).toBe(true)
      })

      test('sets "valid" to true when given "incomplete"', () => {
        expect(parseTextValue('incomplete').valid).toBe(true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        expect(parseTextValue('').valid).toBe(true)
      })

      test('sets "valid" to true when given "EX"', () => {
        expect(parseTextValue('EX').valid).toBe(true)
      })

      test('sets "valid" to true when the value is "MI"', () => {
        expect(parseTextValue('MI').valid).toBe(true)
      })

      test('sets "valid" to false when given any other value', () => {
        expect(parseTextValue('unknown').valid).toBe(false)
      })
    })
  })
})
