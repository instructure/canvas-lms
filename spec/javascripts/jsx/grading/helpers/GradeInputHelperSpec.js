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

import round from 'compiled/util/round'
import * as GradeInputHelper from 'jsx/grading/helpers/GradeInputHelper'

/* eslint-disable qunit/no-identical-names */

QUnit.module('GradeInputHelper', () => {
  QUnit.module('.isExcused()', () => {
    test('returns true when given "EX"', () => {
      strictEqual(GradeInputHelper.isExcused('EX'), true)
    })

    test('returns true when given "ex"', () => {
      strictEqual(GradeInputHelper.isExcused('ex'), true)
    })

    test('returns true when given "EX" with surrounding whitespace', () => {
      strictEqual(GradeInputHelper.isExcused('  EX  '), true)
    })

    test('returns false when given "E X"', () => {
      strictEqual(GradeInputHelper.isExcused('E X'), false)
    })

    test('returns false when given a point value', () => {
      strictEqual(GradeInputHelper.isExcused('7'), false)
    })

    test('returns false when given a percentage value', () => {
      strictEqual(GradeInputHelper.isExcused('7%'), false)
    })

    test('returns false when given a letter grade', () => {
      strictEqual(GradeInputHelper.isExcused('A'), false)
    })

    test('returns false when given an empty string ""', () => {
      strictEqual(GradeInputHelper.isExcused(''), false)
    })

    test('returns false when given null', () => {
      strictEqual(GradeInputHelper.isExcused(null), false)
    })
  })

  QUnit.module('.hasGradeChanged()', hooks => {
    let options
    let pendingGradeInfo
    let submission

    function hasGradeChanged() {
      return GradeInputHelper.hasGradeChanged(submission, pendingGradeInfo, options)
    }

    hooks.beforeEach(() => {
      options = {
        enterGradesAs: 'points',
        gradingScheme: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.5]],
        pointsPossible: 10
      }
      // cleared grade info
      pendingGradeInfo = {
        enteredAs: null,
        excused: false,
        grade: null,
        score: null,
        valid: true
      }
      submission = {enteredGrade: 'A', enteredScore: 10, excused: false, grade: 'B'}
    })

    test('returns true when the pending grade is invalid', () => {
      Object.assign(pendingGradeInfo, {grade: 'invalid', valid: false})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns true when the submission is becoming excused', () => {
      Object.assign(pendingGradeInfo, {enteredAs: 'excused', excused: true})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns true when the submission is becoming unexcused', () => {
      submission = {enteredGrade: null, enteredScore: null, excused: true, grade: null}
      strictEqual(hasGradeChanged(), true)
    })

    QUnit.module('when the pending grade is entered as "points"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.enterGradesAs = 'points'
        Object.assign(pendingGradeInfo, {enteredAs: 'points', grade: 'A', score: 10})
      })

      test('returns false when the pending score matches the entered score', () => {
        strictEqual(hasGradeChanged(), false)
      })

      test('returns true when the pending score does not match the entered score', () => {
        pendingGradeInfo.score = 9.9
        strictEqual(hasGradeChanged(), true)
      })
    })

    QUnit.module('when the pending grade is entered as "percent"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.enterGradesAs = 'percent'
        Object.assign(pendingGradeInfo, {enteredAs: 'percent', grade: 'A', score: 10})
      })

      test('returns false when the pending score matches the entered score', () => {
        strictEqual(hasGradeChanged(), false)
      })

      test('returns true when the pending score does not match the entered score', () => {
        pendingGradeInfo.score = 9.9
        strictEqual(hasGradeChanged(), true)
      })
    })

    QUnit.module('when the pending grade is entered as "gradingScheme"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.enterGradesAs = 'gradingScheme'
        Object.assign(pendingGradeInfo, {enteredAs: 'gradingScheme', grade: 'A', score: 10})
      })

      test('returns false when the pending grade matches the submission grade', () => {
        strictEqual(hasGradeChanged(), false)
      })

      test('returns false when the pending grade matches only the submission grade', () => {
        pendingGradeInfo.score = 9.1
        strictEqual(hasGradeChanged(), false)
      })

      test('returns true when the pending grade does not match the submission grade', () => {
        Object.assign(pendingGradeInfo, {grade: 'B', score: 8.9})
        strictEqual(hasGradeChanged(), true)
      })
    })

    QUnit.module('when the pending grade is entered as "passFail"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.enterGradesAs = 'passFail'
        Object.assign(pendingGradeInfo, {enteredAs: 'passFail', grade: 'complete', score: 10})
        Object.assign(submission, {enteredGrade: 'complete', grade: 'complete'})
      })

      QUnit.module('when the assignment is out of zero points', nestedContextHooks => {
        nestedContextHooks.beforeEach(() => {
          options.pointsPossible = 0
          pendingGradeInfo.score = 0
          submission.score = 0
        })

        test('returns false when the pending grade matches the submission grade', () => {
          strictEqual(hasGradeChanged(), false)
        })

        test('returns true when the pending grade differs from the submission grade', () => {
          pendingGradeInfo.grade = 'incomplete'
          strictEqual(hasGradeChanged(), true)
        })
      })

      test('returns false when the pending score matches the submission score', () => {
        strictEqual(hasGradeChanged(), false)
      })

      test('returns true when the pending score differs from the submission score', () => {
        pendingGradeInfo.score = 0
        strictEqual(hasGradeChanged(), true)
      })
    })
  })

  QUnit.module('.parseTextValue()', () => {
    let options

    function parseTextValue(value) {
      return GradeInputHelper.parseTextValue(value, options)
    }

    QUnit.module('when the "enter grades as" setting is "points"', hooks => {
      hooks.beforeEach(() => {
        options = {
          enterGradesAs: 'points',
          gradingScheme: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.5]],
          pointsPossible: 10
        }
      })

      test('stringifies the value for grade when given an integer', () => {
        strictEqual(parseTextValue(8).grade, '8')
      })

      test('sets the grade to the value when given a stringified integer', () => {
        strictEqual(parseTextValue('8').grade, '8')
      })

      test('ignores whitespace from the given value', () => {
        strictEqual(parseTextValue(' 8 ').grade, '8')
      })

      test('stringifies the value for grade when given a decimal', () => {
        strictEqual(parseTextValue(8.34).grade, '8.34')
      })

      test('sets the grade to the value when given a stringified decimal', () => {
        strictEqual(parseTextValue('8.34').grade, '8.34')
      })

      test('rounds points to 15 decimal places', () => {
        strictEqual(parseTextValue('8.12345678901234567890').grade, '8.123456789012346')
      })

      test('converts an integer percentage value to points for the grade', () => {
        strictEqual(parseTextValue('80%').grade, '8')
      })

      test('converts a decimal percentage value to points for the grade', () => {
        strictEqual(parseTextValue('83.4%').grade, '8.34')
      })

      test('rounds a converted percentage grade to 15 decimal places', () => {
        strictEqual(parseTextValue('83.12345678901234567890%').grade, '8.312345678901234')
      })

      test('converts percentages using the "％" symbol', () => {
        strictEqual(parseTextValue('83.35％').grade, '8.335')
      })

      test('converts percentages using the "﹪" symbol', () => {
        strictEqual(parseTextValue('83.35﹪').grade, '8.335')
      })

      test('converts percentages using the "٪" symbol', () => {
        strictEqual(parseTextValue('83.35٪').grade, '8.335')
      })

      test('sets the grade to the numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').grade, '3')
      })

      test('sets the grade using the matching scheme key when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').grade, '8.9')
      })

      test('sets the grade to the given points when given no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('8.3').grade, '8.3')
      })

      test('sets the grade to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('83.45%').grade, '0')
      })

      test('sets the grade to zero when given zero', () => {
        strictEqual(parseTextValue(0).grade, '0')
      })

      test('converts a grading scheme value to points for the grade', () => {
        strictEqual(parseTextValue('B').grade, '8.9')
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        strictEqual(parseTextValue(' B ').grade, '8.9')
      })

      test('sets the grade to the given non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').grade, 'B-')
      })

      test('sets the grade to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').grade, null)
      })

      test('sets the grade to null when the value is null', () => {
        strictEqual(parseTextValue(null).grade, null)
      })

      test('sets the grade to the given non-numerical string when given no grading scheme', () => {
        options.gradingScheme = null
        strictEqual(parseTextValue('B').grade, 'B')
      })

      test('sets the score to the value when given an integer', () => {
        strictEqual(parseTextValue(8).score, 8)
      })

      test('parses the value for score when given a stringified integer', () => {
        strictEqual(parseTextValue('8').score, 8)
      })

      test('sets the score to the value when given a decimal', () => {
        strictEqual(parseTextValue(8.34).score, 8.34)
      })

      test('parses the value for score when given a stringified decimal', () => {
        strictEqual(parseTextValue('8.34').score, 8.34)
      })

      test('rounds points to 15 decimal places', () => {
        strictEqual(parseTextValue('8.12345678901234567890').score, 8.123456789012346)
      })

      test('converts an integer percentage value to points for the score', () => {
        strictEqual(parseTextValue('80%').score, 8)
      })

      test('converts a decimal percentage value to points for the score', () => {
        strictEqual(parseTextValue('83.4%').score, 8.34)
      })

      test('converts a percentage using alternate points possible', () => {
        options.pointsPossible = 15
        strictEqual(parseTextValue('80%').score, 12)
      })

      test('rounds a converted percentage score to 15 decimal places', () => {
        strictEqual(parseTextValue('83.12345678901234567890%').score, 8.312345678901234)
      })

      test('converts percentages using the "％" symbol', () => {
        strictEqual(parseTextValue('83.35％').score, 8.335)
      })

      test('converts percentages using the "﹪" symbol', () => {
        strictEqual(parseTextValue('83.35﹪').score, 8.335)
      })

      test('converts percentages using the "٪" symbol', () => {
        strictEqual(parseTextValue('83.35٪').score, 8.335)
      })

      test('sets the score to the numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').score, 3)
      })

      test('sets the score using the matching scheme key when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').score, 8.9)
      })

      test('sets the score to the given points when given no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('8.3').score, 8.3)
      })

      test('sets the score to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('83.45%').score, 0)
      })

      test('sets the score to zero when given zero', () => {
        strictEqual(parseTextValue(0).score, 0)
      })

      test('converts a grading scheme value to points for the score', () => {
        strictEqual(parseTextValue('B').score, 8.9)
      })

      test('converts a grading scheme value using alternate points possible', () => {
        options.pointsPossible = 15
        strictEqual(parseTextValue('B').score, 13.35)
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        strictEqual(parseTextValue(' B ').score, 8.9)
      })

      test('sets a grading scheme score to zero when given 0 points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('B').score, 0)
      })

      test('sets a grading scheme score to zero when given null points possible', () => {
        options.pointsPossible = null
        strictEqual(parseTextValue('B').score, 0)
      })

      test('sets the score to null when given a non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').score, null)
      })

      test('sets the score to null when given no grading scheme for a non-numerical string', () => {
        options.gradingScheme = null
        strictEqual(parseTextValue('B').score, null)
      })

      test('sets the score to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').score, null)
      })

      test('sets the score to null when the value is null', () => {
        strictEqual(parseTextValue(null).score, null)
      })

      test('sets the grade to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').grade, null)
      })

      test('sets the score to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').score, null)
      })

      test('ignores whitespace around the excused value "EX"', () => {
        strictEqual(parseTextValue(' EX ').excused, true)
      })

      test('sets excused to true when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').excused, true)
      })

      test('sets excused to false for any other value', () => {
        strictEqual(parseTextValue('E X').excused, false)
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        strictEqual(parseTextValue('EX').enteredAs, 'excused')
      })

      test('sets "enteredAs" to "points" when given points', () => {
        strictEqual(parseTextValue('8.34').enteredAs, 'points')
      })

      test('sets "enteredAs" to "percent" when given a percentage', () => {
        strictEqual(parseTextValue('83.45%').enteredAs, 'percent')
      })

      test('sets "enteredAs" to "gradingScheme" when given a grading scheme key', () => {
        strictEqual(parseTextValue('B').enteredAs, 'gradingScheme')
      })

      test('sets "enteredAs" to "points" when given a numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').enteredAs, 'points')
      })

      test('sets "enteredAs" to "gradingScheme" when given a percentage value which matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').enteredAs, 'gradingScheme')
      })

      test('sets "enteredAs" to null when given a non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').enteredAs, null)
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        strictEqual(parseTextValue('').enteredAs, null)
      })

      test('sets "valid" to true when the grade is a valid point value', () => {
        strictEqual(parseTextValue('8.34').valid, true)
      })

      test('sets "valid" to true when the grade is a valid percentage', () => {
        strictEqual(parseTextValue('83.4%').valid, true)
      })

      test('sets "valid" to true when the grade is a valid grading scheme key', () => {
        strictEqual(parseTextValue('B').valid, true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        strictEqual(parseTextValue('').valid, true)
      })

      test('sets "valid" to true when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').valid, true)
      })

      test('sets "valid" to false when given non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').valid, false)
      })
    })

    QUnit.module('when the "enter grades as" setting is "percent"', hooks => {
      hooks.beforeEach(() => {
        options = {
          enterGradesAs: 'percent',
          gradingScheme: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.5]],
          pointsPossible: 10
        }
      })

      test('stringifies the value for grade when given an integer', () => {
        strictEqual(parseTextValue(8).grade, '8%')
      })

      test('sets the grade to the value when given a stringified integer', () => {
        strictEqual(parseTextValue('8').grade, '8%')
      })

      test('ignores whitespace from the given value', () => {
        strictEqual(parseTextValue(' 8 ').grade, '8%')
      })

      test('stringifies the value for grade when given a decimal', () => {
        strictEqual(parseTextValue(8.34).grade, '8.34%')
      })

      test('sets the grade to the value when given a stringified decimal', () => {
        strictEqual(parseTextValue('8.34').grade, '8.34%')
      })

      test('rounds points to 15 decimal places', () => {
        strictEqual(parseTextValue('8.12345678901234567890').grade, '8.123456789012346%')
      })

      test('uses the given integer percentage value for the grade', () => {
        strictEqual(parseTextValue('8%').grade, '8%')
      })

      test('uses the given decimal percentage value for the grade', () => {
        strictEqual(parseTextValue('8.34%').grade, '8.34%')
      })

      test('rounds a converted percentage grade to 15 decimal places', () => {
        strictEqual(parseTextValue('83.12345678901234567890%').grade, '83.12345678901235%')
      })

      test('converts percentages using the "％" symbol', () => {
        strictEqual(parseTextValue('83.35％').grade, '83.35%')
      })

      test('converts percentages using the "﹪" symbol', () => {
        strictEqual(parseTextValue('83.35﹪').grade, '83.35%')
      })

      test('converts percentages using the "٪" symbol', () => {
        strictEqual(parseTextValue('83.35٪').grade, '83.35%')
      })

      test('sets the grade to the numerical value as a percentage even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').grade, '3%')
      })

      test('sets the grade to the percentage value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').grade, '85%')
      })

      test('sets the score to the given points when given no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('8.3').grade, '8.3%')
      })

      test('sets the grade to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('83.45%').grade, '0%')
      })

      test('sets the grade to zero when given zero', () => {
        strictEqual(parseTextValue(0).grade, '0%')
      })

      test('converts a grading scheme value to a percentage for the grade', () => {
        strictEqual(parseTextValue('B').grade, '89%')
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        strictEqual(parseTextValue(' B ').grade, '89%')
      })

      test('sets the grade to the given non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').grade, 'B-')
      })

      test('sets the grade to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').grade, null)
      })

      test('sets the grade to the given non-numerical string when given no grading scheme', () => {
        options.gradingScheme = null
        strictEqual(parseTextValue('B').grade, 'B')
      })

      test('sets the score to the result of the value divided by points possible when given an integer', () => {
        strictEqual(parseTextValue(8).score, 0.8)
      })

      test('parses the value for score when given a stringified integer', () => {
        strictEqual(parseTextValue('8').score, 0.8)
      })

      test('sets the score to the value when given a decimal', () => {
        strictEqual(parseTextValue(8.3).score, 0.83)
      })

      test('parses the value for score when given a stringified decimal', () => {
        strictEqual(parseTextValue('8.3').score, 0.83)
      })

      test('rounds points to 15 decimal places', () => {
        strictEqual(parseTextValue('8.12345678901234567890').score, 0.812345678901235)
      })

      test('preserves the precision of a converted point score', () => {
        // 83.543 / 100 * 10 (points possible) === 8.354300000000002 in JavaScript
        strictEqual(parseTextValue(83.543).score, 8.3543)
      })

      test('preserves a precision arbitrarily longer than the percentage grade precision', () => {
        options.pointsPossible = 9.5
        strictEqual(parseTextValue('55').score, 5.225)
      })

      test('converts an integer percentage value to points for the score', () => {
        strictEqual(parseTextValue('80%').score, 8)
      })

      test('converts a decimal percentage value to points for the score', () => {
        strictEqual(parseTextValue('83.4%').score, 8.34)
      })

      test('converts a percentage using alternate points possible', () => {
        options.pointsPossible = 15
        strictEqual(parseTextValue('80%').score, 12)
      })

      test('rounds a converted percentage score to 15 decimal places', () => {
        strictEqual(parseTextValue('83.12345678901234567890%').score, 8.312345678901234)
      })

      test('converts percentages using the "％" symbol', () => {
        strictEqual(parseTextValue('83.35％').score, 8.335)
      })

      test('converts percentages using the "﹪" symbol', () => {
        strictEqual(parseTextValue('83.35﹪').score, 8.335)
      })

      test('converts percentages using the "٪" symbol', () => {
        strictEqual(parseTextValue('83.35٪').score, 8.335)
      })

      test('sets the score to the numerical value as a percentage even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').score, 0.3)
      })

      test('sets the score to the percentage value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').score, 8.5)
      })

      test('parses a point value as a percentage for score when given no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('8.3').score, 8.3)
      })

      test('sets the score to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('83.45%').score, 0)
      })

      test('sets the score to zero when given zero', () => {
        strictEqual(parseTextValue(0).score, 0)
      })

      test('converts a grading scheme value to points for the score', () => {
        strictEqual(parseTextValue('B').score, 8.9)
      })

      test('converts a grading scheme value using alternate points possible', () => {
        options.pointsPossible = 15
        strictEqual(parseTextValue('B').score, 13.35)
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        strictEqual(parseTextValue(' B ').score, 8.9)
      })

      test('sets a grading scheme score to zero when given 0 points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('B').score, 0)
      })

      test('sets a grading scheme score to zero when given null points possible', () => {
        options.pointsPossible = null
        strictEqual(parseTextValue('B').score, 0)
      })

      test('sets the score to null when given a non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').score, null)
      })

      test('sets the score to null when given no grading scheme for a non-numerical string', () => {
        options.gradingScheme = null
        strictEqual(parseTextValue('B').score, null)
      })

      test('sets the score to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').score, null)
      })

      test('sets the grade to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').grade, null)
      })

      test('sets the score to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').score, null)
      })

      test('sets excused to true when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').excused, true)
      })

      test('sets excused to false for any other value', () => {
        strictEqual(parseTextValue('E X').excused, false)
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        strictEqual(parseTextValue('EX').enteredAs, 'excused')
      })

      test('sets "enteredAs" to "percent" when given points', () => {
        strictEqual(parseTextValue('8.34').enteredAs, 'percent')
      })

      test('sets "enteredAs" to "percent" when given a percentage', () => {
        strictEqual(parseTextValue('83.45%').enteredAs, 'percent')
      })

      test('sets "enteredAs" to "gradingScheme" when given a grading scheme key', () => {
        strictEqual(parseTextValue('B').enteredAs, 'gradingScheme')
      })

      test('sets "enteredAs" to "percent" when given a numerical value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').enteredAs, 'percent')
      })

      test('sets "enteredAs" to "percent" when given a percentage value even when it matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').enteredAs, 'percent')
      })

      test('sets "enteredAs" to null when given a non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').enteredAs, null)
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        strictEqual(parseTextValue('').enteredAs, null)
      })

      test('sets "valid" to true when the grade is a valid point value', () => {
        strictEqual(parseTextValue('8.34').valid, true)
      })

      test('sets "valid" to true when the grade is a valid percentage', () => {
        strictEqual(parseTextValue('83.4%').valid, true)
      })

      test('sets "valid" to true when the grade is a valid grading scheme key', () => {
        strictEqual(parseTextValue('B').valid, true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        strictEqual(parseTextValue('').valid, true)
      })

      test('sets "valid" to true when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').valid, true)
      })

      test('sets "valid" to false when given non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').valid, false)
      })
    })

    QUnit.module('when the "enter grades as" setting is "gradingScheme"', hooks => {
      hooks.beforeEach(() => {
        options = {
          enterGradesAs: 'gradingScheme',
          gradingScheme: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.5]],
          pointsPossible: 10
        }
      })

      test('sets the grade to the matching scheme key when given an integer', () => {
        strictEqual(parseTextValue('B').grade, 'B')
      })

      test('uses the exact scheme key when matching with different case', () => {
        strictEqual(parseTextValue('b').grade, 'B')
      })

      test('sets the grade to the matching scheme key when given an integer', () => {
        strictEqual(parseTextValue(8).grade, 'B')
      })

      test('sets the grade to the matching scheme key when given a stringified integer', () => {
        strictEqual(parseTextValue('8').grade, 'B')
      })

      test('sets the grade to the matching scheme key when given an decimal', () => {
        strictEqual(parseTextValue(8.34).grade, 'B')
      })

      test('sets the grade to the matching scheme key when given a stringified decimal', () => {
        strictEqual(parseTextValue('8.34').grade, 'B')
      })

      test('uses the given percentage value to match a scheme value for the grade', () => {
        strictEqual(parseTextValue('83.45%').grade, 'B')
      })

      test('converts percentages using the "％" symbol', () => {
        strictEqual(parseTextValue('83.35％').grade, 'B')
      })

      test('converts percentages using the "﹪" symbol', () => {
        strictEqual(parseTextValue('83.35﹪').grade, 'B')
      })

      test('converts percentages using the "٪" symbol', () => {
        strictEqual(parseTextValue('83.35٪').grade, 'B')
      })

      test('sets the grade to the matching scheme key when given a numerical scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').grade, '3.0')
      })

      test('sets the grade to the matching scheme key when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('95%').grade, '95%')
      })

      test('sets the grade to the lowest scheme value when given a point value and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('8.34').grade, 'F')
      })

      test('sets the grade to the lowest scheme value when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('83.45%').grade, 'F')
      })

      test('sets the grade to the given scheme value even when given no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('B').grade, 'B')
      })

      test('sets the to the lowest scheme value when given zero', () => {
        strictEqual(parseTextValue(0).grade, 'F')
      })

      test('ignores whitespace from the given value when setting the grade', () => {
        strictEqual(parseTextValue(' B ').grade, 'B')
      })

      test('sets the grade to the given non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').grade, 'B-')
      })

      test('sets the grade to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').grade, null)
      })

      test('sets the grade to the given non-numerical string when given no grading scheme', () => {
        options.gradingScheme = null
        strictEqual(parseTextValue('B').grade, 'B')
      })

      test('sets the score to the matching scheme value when given a scheme key', () => {
        strictEqual(parseTextValue('B').score, 8.9)
      })

      test('sets the score using alternate points possible', () => {
        options.pointsPossible = 15
        strictEqual(parseTextValue('B').score, 13.35)
      })

      test('sets the score to the value when given an integer', () => {
        strictEqual(parseTextValue(8).score, 8)
      })

      test('parses the value for score when given a stringified integer', () => {
        strictEqual(parseTextValue('8').score, 8)
      })

      test('sets the score to the value when given a decimal', () => {
        strictEqual(parseTextValue(8.34).score, 8.34)
      })

      test('parses the value for score when given a stringified decimal', () => {
        strictEqual(parseTextValue('8.34').score, 8.34)
      })

      test('rounds points to 15 decimal places', () => {
        strictEqual(parseTextValue('8.12345678901234567890').score, 8.123456789012346)
      })

      test('preserves the precision of a given point score', () => {
        // 8.536 / 10 (points possible) * 100 === 8.535999999999998 in JavaScript
        strictEqual(parseTextValue(8.536).score, 8.536)
      })

      test('converts an integer percentage value to points for the score', () => {
        strictEqual(parseTextValue('80%').score, 8)
      })

      test('converts a decimal percentage value to points for the score', () => {
        strictEqual(parseTextValue('83.4%').score, 8.34)
      })

      test('rounds a converted percentage score to 15 decimal places', () => {
        strictEqual(parseTextValue('83.12345678901234567890%').score, 8.312345678901234)
      })

      test('converts percentages using the "％" symbol', () => {
        strictEqual(parseTextValue('83.35％').score, 8.335)
      })

      test('converts percentages using the "﹪" symbol', () => {
        strictEqual(parseTextValue('83.35﹪').score, 8.335)
      })

      test('converts percentages using the "٪" symbol', () => {
        strictEqual(parseTextValue('83.35٪').score, 8.335)
      })

      test('sets the score to the matching scheme value when given a numerical scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').score, 8.9)
      })

      test('sets the score to the matching scheme value when given a percentage scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').score, 8.9)
      })

      test('sets the score to the value when given a point value and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('8.34').score, 8.34)
      })

      test('sets the score to zero when given a percentage and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('83.45%').score, 0)
      })

      test('sets the score to zero when given a grading scheme key and 0 points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('B').score, 0)
      })

      test('sets the score to zero when given a grading scheme key and null points possible', () => {
        options.pointsPossible = null
        strictEqual(parseTextValue('B').score, 0)
      })

      test('sets the score to zero when given zero', () => {
        strictEqual(parseTextValue(0).score, 0)
      })

      test('sets the score to null when given a non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').score, null)
      })

      test('sets the score to null when given no grading scheme for a non-numerical string', () => {
        options.gradingScheme = null
        strictEqual(parseTextValue('B').score, null)
      })

      test('sets the score to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').score, null)
      })

      test('sets the grade to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').grade, null)
      })

      test('sets the score to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').score, null)
      })

      test('ignores whitespace around the excused value "EX"', () => {
        strictEqual(parseTextValue(' EX ').excused, true)
      })

      test('sets excused to true when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').excused, true)
      })

      test('sets excused to false for any other value', () => {
        strictEqual(parseTextValue('E X').excused, false)
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        strictEqual(parseTextValue('EX').enteredAs, 'excused')
      })

      test('sets "enteredAs" to "points" when given points', () => {
        strictEqual(parseTextValue('8.34').enteredAs, 'points')
      })

      test('sets "enteredAs" to "percent" when given a percentage', () => {
        strictEqual(parseTextValue('83.45%').enteredAs, 'percent')
      })

      test('sets "enteredAs" to "gradingScheme" when given a grading scheme key', () => {
        strictEqual(parseTextValue('B').enteredAs, 'gradingScheme')
      })

      test('sets "enteredAs" to "gradingScheme" when given a numerical value which matches a grading scheme key', () => {
        options.gradingScheme = [
          ['4.0', 0.9],
          ['3.0', 0.8],
          ['2.0', 0.7],
          ['1.0', 0.6],
          ['0.0', 0.5]
        ]
        strictEqual(parseTextValue('3.0').enteredAs, 'gradingScheme')
      })

      test('sets "enteredAs" to "gradingScheme" when given a percentage value which matches a grading scheme key', () => {
        options.gradingScheme = [
          ['95%', 0.9],
          ['85%', 0.8],
          ['75%', 0.7],
          ['65%', 0.6],
          ['0%', 0.5]
        ]
        strictEqual(parseTextValue('85%').enteredAs, 'gradingScheme')
      })

      test('sets "enteredAs" to null when given a non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').enteredAs, null)
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        strictEqual(parseTextValue('').enteredAs, null)
      })

      test('sets "valid" to true when the grade is a valid point value', () => {
        strictEqual(parseTextValue('8.34').valid, true)
      })

      test('sets "valid" to true when the grade is a valid percentage', () => {
        strictEqual(parseTextValue('83.4%').valid, true)
      })

      test('sets "valid" to true when the grade is a valid grading scheme key', () => {
        strictEqual(parseTextValue('B').valid, true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        strictEqual(parseTextValue('').valid, true)
      })

      test('sets "valid" to true when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').valid, true)
      })

      test('sets "valid" to false when given non-numerical string not in the grading scheme', () => {
        strictEqual(parseTextValue('B-').valid, false)
      })
    })

    QUnit.module('when the "enter grades as" setting is "passFail"', hooks => {
      hooks.beforeEach(() => {
        options = {
          enterGradesAs: 'passFail',
          pointsPossible: 10
        }
      })

      test('sets the grade to "complete" when given "complete"', () => {
        strictEqual(parseTextValue('complete').grade, 'complete')
      })

      test('ignores case for "complete" value', () => {
        strictEqual(parseTextValue('COMplete').grade, 'complete')
      })

      test('ignores whitespace for "complete" value', () => {
        strictEqual(parseTextValue(' complete ').grade, 'complete')
      })

      test('sets the grade to "incomplete" when given "incomplete"', () => {
        strictEqual(parseTextValue('incomplete').grade, 'incomplete')
      })

      test('ignores case for "incomplete" value', () => {
        strictEqual(parseTextValue('INComplete').grade, 'incomplete')
      })

      test('ignores whitespace for "incomplete" value', () => {
        strictEqual(parseTextValue(' incomplete ').grade, 'incomplete')
      })

      test('sets the grade to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').grade, null)
      })

      test('sets the score to the points possible when given "complete"', () => {
        strictEqual(parseTextValue('complete').score, 10)
      })

      test('sets the score to zero when given "complete" and no points possible', () => {
        options.pointsPossible = 0
        strictEqual(parseTextValue('complete').score, 0)
      })

      test('sets the score to zero when given "complete" and null points possible', () => {
        options.pointsPossible = null
        strictEqual(parseTextValue('complete').score, 0)
      })

      test('sets the score to zero when given "incomplete"', () => {
        strictEqual(parseTextValue('incomplete').score, 0)
      })

      test('sets the score to null when the value is blank', () => {
        strictEqual(parseTextValue('  ').score, null)
      })

      test('sets the grade to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').grade, null)
      })

      test('sets the score to null when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').score, null)
      })

      test('ignores whitespace around the excused value "EX"', () => {
        strictEqual(parseTextValue(' EX ').excused, true)
      })

      test('sets excused to true when the value is "EX"', () => {
        strictEqual(parseTextValue('EX').excused, true)
      })

      test('sets excused to false when the value is "complete"', () => {
        strictEqual(parseTextValue('complete').excused, false)
      })

      test('sets excused to false when the value is "incomplete"', () => {
        strictEqual(parseTextValue('incomplete').excused, false)
      })

      test('sets excused to false for invalid values', () => {
        strictEqual(parseTextValue('E X').excused, false)
      })

      test('sets "enteredAs" to "excused" when given "EX"', () => {
        strictEqual(parseTextValue('EX').enteredAs, 'excused')
      })

      test('sets "enteredAs" to "passFail" when given "complete"', () => {
        strictEqual(parseTextValue('complete').enteredAs, 'passFail')
      })

      test('sets "enteredAs" to "passFail" when given "incomplete"', () => {
        strictEqual(parseTextValue('incomplete').enteredAs, 'passFail')
      })

      test('sets "enteredAs" to null when the grade is cleared', () => {
        strictEqual(parseTextValue('').enteredAs, null)
      })

      test('sets "enteredAs" to null when given any other value', () => {
        strictEqual(parseTextValue('unknown').enteredAs, null)
      })

      test('sets "valid" to true when given "complete"', () => {
        strictEqual(parseTextValue('complete').valid, true)
      })

      test('sets "valid" to true when given "incomplete"', () => {
        strictEqual(parseTextValue('incomplete').valid, true)
      })

      test('sets "valid" to true when the grade is cleared', () => {
        strictEqual(parseTextValue('').valid, true)
      })

      test('sets "valid" to true when given "EX"', () => {
        strictEqual(parseTextValue('EX').valid, true)
      })

      test('sets "valid" to false when given any other value', () => {
        strictEqual(parseTextValue('unknown').valid, false)
      })
    })
  })
})
