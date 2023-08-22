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

import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const I18n = useI18nScope('sharedGradeFormatHelper')

QUnit.module('GradeFormatHelper#formatGrade', {
  setup() {
    this.translateString = I18n.t
    sandbox.stub(numberHelper, 'validate').callsFake(val => !Number.isNaN(parseFloat(val)))
    sandbox.stub(I18n.constructor.prototype, 't').callsFake(this.translateString)
  },
})

test('uses I18n#n to format numerical integer grades', () => {
  sandbox.stub(I18n.constructor.prototype, 'n').withArgs(1000).returns('* 1,000')
  equal(GradeFormatHelper.formatGrade(1000), '* 1,000')
  equal(I18n.n.callCount, 1)
})

test('uses formatPointsOutOf to format points grade type', () => {
  equal(
    GradeFormatHelper.formatGrade('4', {
      gradingType: 'points',
      pointsPossible: '7',
      formatType: 'points_out_of_fraction',
    }),
    '4/7'
  )
})

test('uses I18n#n to format numerical decimal grades', () => {
  sandbox.stub(I18n.constructor.prototype, 'n').withArgs(123.45).returns('* 123.45')
  equal(GradeFormatHelper.formatGrade(123.45), '* 123.45')
  equal(I18n.n.callCount, 1)
})

test('uses I18n#t to format pass_fail based grades: complete', () => {
  I18n.t.withArgs('complete').returns('* complete')
  equal(GradeFormatHelper.formatGrade('complete'), '* complete')
})

test('uses I18n#t to format pass_fail based grades: pass', () => {
  I18n.t.withArgs('complete').returns('* complete')
  equal(GradeFormatHelper.formatGrade('pass'), '* complete')
})

test('uses I18n#t to format pass_fail based grades: incomplete', () => {
  I18n.t.withArgs('incomplete').returns('* incomplete')
  equal(GradeFormatHelper.formatGrade('incomplete'), '* incomplete')
})

test('uses I18n#t to format pass_fail based grades: fail', () => {
  I18n.t.withArgs('incomplete').returns('* incomplete')
  equal(GradeFormatHelper.formatGrade('fail'), '* incomplete')
})

test('returns "Excused" when the grade is "EX"', () => {
  // this is for backwards compatibility for users who depend on this behavior
  equal(GradeFormatHelper.formatGrade('EX'), 'Excused')
})

test('parses a stringified integer percentage grade when it is a valid number', () => {
  sandbox.spy(numberHelper, 'parse')
  GradeFormatHelper.formatGrade('32%')
  equal(numberHelper.parse.callCount, 1)
  strictEqual(numberHelper.parse.getCall(0).args[0], '32')
})

test('returns the given grade when it is not a valid number', () => {
  equal(GradeFormatHelper.formatGrade('!32%'), '!32%')
})

test('returns the given grade when it is a letter grade', () => {
  equal(GradeFormatHelper.formatGrade('A'), 'A')
})

test('replaces trailing en-dash characters with minus characters', () => {
  equal(GradeFormatHelper.formatGrade('B-', {gradingType: 'letter_grade'}), 'B−')
})

test('does not transform en-dash characters that are not trailing', () => {
  equal(
    GradeFormatHelper.formatGrade('smarty-pants', {gradingType: 'letter_grade'}),
    'smarty-pants'
  )
})

test('returns the given grade when it is a mix of letters and numbers', () => {
  equal(GradeFormatHelper.formatGrade('A3'), 'A3')
})

test('returns the given grade when it is numbers followed by letters', () => {
  equal(GradeFormatHelper.formatGrade('1E', {delocalize: false}), '1E')
})

test('does not format letter grades', () => {
  sandbox.spy(I18n.constructor.prototype, 'n')
  GradeFormatHelper.formatGrade('A')
  equal(I18n.n.callCount, 0, 'I18n.n was not called')
})

test('returns the defaultValue option when grade is undefined', () => {
  equal(GradeFormatHelper.formatGrade(undefined, {defaultValue: 'no grade'}), 'no grade')
})

test('returns the defaultValue option when grade is null', () => {
  equal(GradeFormatHelper.formatGrade(null, {defaultValue: 'no grade'}), 'no grade')
})

test('returns the defaultValue option when grade is an empty string', () => {
  equal(GradeFormatHelper.formatGrade('', {defaultValue: 'no grade'}), 'no grade')
})

test('returns the grade when given undefined and no defaultValue option', () => {
  strictEqual(GradeFormatHelper.formatGrade(undefined), undefined)
})

test('returns the grade when given null and no defaultValue option', () => {
  strictEqual(GradeFormatHelper.formatGrade(null), null)
})

test('returns the grade when given an empty string and no defaultValue option', () => {
  strictEqual(GradeFormatHelper.formatGrade(''), '')
})

test('formats numerical integer grades as percent when given a gradingType of "percent"', () => {
  sandbox.spy(I18n.constructor.prototype, 'n')
  GradeFormatHelper.formatGrade(10, {gradingType: 'percent'})
  const [value, options] = I18n.n.getCall(0).args
  strictEqual(value, 10)
  strictEqual(options.percentage, true)
})

test('formats numerical decimal grades as percent when given a gradingType of "percent"', () => {
  sandbox.spy(I18n.constructor.prototype, 'n')
  GradeFormatHelper.formatGrade(10.1, {gradingType: 'percent'})
  const [value, options] = I18n.n.getCall(0).args
  strictEqual(value, 10.1)
  strictEqual(options.percentage, true)
})

test('formats string percentage grades as points when given a gradingType of "points"', () => {
  sandbox.spy(I18n.constructor.prototype, 'n')
  GradeFormatHelper.formatGrade('10%', {gradingType: 'points'})
  const [value, options] = I18n.n.getCall(0).args
  strictEqual(value, 10)
  strictEqual(options.percentage, false)
})

test('rounds grades to two decimal places', () => {
  equal(GradeFormatHelper.formatGrade(10.321), '10.32')
  equal(GradeFormatHelper.formatGrade(10.325), '10.33')
})

test('rounds very small scores to two decimal places', () => {
  strictEqual(GradeFormatHelper.formatGrade('.00000001', {gradingType: 'points'}), '0')
})

test('scientific notation grades show as rounded numeric grades', () => {
  equal(GradeFormatHelper.formatGrade('1e-8', {gradingType: 'points'}), '0')
})

test('optionally rounds to a given precision', () => {
  equal(GradeFormatHelper.formatGrade(10.321, {precision: 3}), '10.321')
})

test('optionally parses grades as non-localized', () => {
  sandbox.stub(numberHelper, 'parse').withArgs('32.459').returns(32459)
  const formatted = GradeFormatHelper.formatGrade('32.459', {delocalize: false})

  strictEqual(numberHelper.parse.callCount, 0)
  strictEqual(formatted, '32.46')
})

QUnit.module('GradeFormatHelper#delocalizeGrade')

test('returns input value when input is not a string', () => {
  strictEqual(GradeFormatHelper.delocalizeGrade(1), 1)
  ok(Number.isNaN(GradeFormatHelper.delocalizeGrade(NaN)))
  strictEqual(GradeFormatHelper.delocalizeGrade(null), null)
  strictEqual(GradeFormatHelper.delocalizeGrade(undefined), undefined)
  strictEqual(GradeFormatHelper.delocalizeGrade(true), true)
})

test('returns input value when input is not a percent or point value', () => {
  strictEqual(GradeFormatHelper.delocalizeGrade('A+'), 'A+')
  strictEqual(GradeFormatHelper.delocalizeGrade('F'), 'F')
  strictEqual(GradeFormatHelper.delocalizeGrade('Pass'), 'Pass')
})

test('returns non-localized point value when given a point value', () => {
  const sandbox = sinon.createSandbox()
  sandbox.stub(numberHelper, 'parse').returns(123.45)
  equal(GradeFormatHelper.delocalizeGrade('123,45'), '123.45')
  ok(numberHelper.parse.calledWith('123,45'))
  sandbox.restore()
})

test('returns non-localized percent value when given a percent value', () => {
  const sandbox = sinon.createSandbox()
  sandbox.stub(numberHelper, 'parse').returns(12.34)
  equal(GradeFormatHelper.delocalizeGrade('12,34%'), '12.34%')
  ok(numberHelper.parse.calledWith('12,34'))
  sandbox.restore()
})

QUnit.module('GradeFormatHelper#parseGrade')

test('parses stringified integer grades', () => {
  strictEqual(GradeFormatHelper.parseGrade('123'), 123)
})

test('parses stringified decimal grades', () => {
  strictEqual(GradeFormatHelper.parseGrade('123.456'), 123.456)
})

test('parses stringified integer percentages', () => {
  strictEqual(GradeFormatHelper.parseGrade('123%'), 123)
})

test('parses stringified decimal percentages', () => {
  strictEqual(GradeFormatHelper.parseGrade('123.456%'), 123.456)
})

test('uses numberHelper.parse to parse a stringified integer grade', () => {
  sandbox.spy(numberHelper, 'parse')
  GradeFormatHelper.parseGrade('123')
  equal(numberHelper.parse.callCount, 1)
})

test('uses numberHelper.parse to parse a stringified decimal grade', () => {
  sandbox.spy(numberHelper, 'parse')
  GradeFormatHelper.parseGrade('123.456')
  equal(numberHelper.parse.callCount, 1)
})

test('uses numberHelper.parse to parse a stringified integer percentage', () => {
  sandbox.spy(numberHelper, 'parse')
  GradeFormatHelper.parseGrade('123%')
  equal(numberHelper.parse.callCount, 1)
})

test('uses numberHelper.parse to parse a stringified decimal percentage', () => {
  sandbox.spy(numberHelper, 'parse')
  GradeFormatHelper.parseGrade('123.456%')
  equal(numberHelper.parse.callCount, 1)
})

test('returns numerical grades without parsing', () => {
  equal(GradeFormatHelper.parseGrade(123.45), 123.45)
})

test('returns letter grades without parsing', () => {
  equal(GradeFormatHelper.parseGrade('A'), 'A')
})

test('returns other string values without parsing', () => {
  equal(GradeFormatHelper.parseGrade('!123'), '!123')
})

test('returns undefined when given undefined', () => {
  strictEqual(GradeFormatHelper.parseGrade(undefined), undefined)
})

test('returns null when given null', () => {
  strictEqual(GradeFormatHelper.parseGrade(null), null)
})

test('returns an empty string when given an empty string', () => {
  strictEqual(GradeFormatHelper.parseGrade(''), '')
})

test('optionally parses grades without delocalizing', () => {
  sandbox.spy(numberHelper, 'parse')
  GradeFormatHelper.parseGrade('123', {delocalize: false})
  equal(numberHelper.parse.callCount, 0)
})

test('parses stringified integer grades without delocalizing', () => {
  strictEqual(GradeFormatHelper.parseGrade('123', {delocalize: false}), 123)
})

test('parses stringified decimal grades without delocalizing', () => {
  strictEqual(GradeFormatHelper.parseGrade('123.456', {delocalize: false}), 123.456)
})

test('parses stringified integer percentages without delocalizing', () => {
  strictEqual(GradeFormatHelper.parseGrade('123%', {delocalize: false}), 123)
})

test('parses stringified decimal percentages without delocalizing', () => {
  strictEqual(GradeFormatHelper.parseGrade('123.456%', {delocalize: false}), 123.456)
})

QUnit.module('GradeFormatHelper', suiteHooks => {
  const translateString = I18n.t

  suiteHooks.beforeEach(() => {
    sinon.stub(numberHelper, 'validate').callsFake(val => !Number.isNaN(parseFloat(val)))
    sinon.stub(I18n.constructor.prototype, 't').callsFake(translateString)
  })

  suiteHooks.afterEach(() => {
    I18n.t.restore()
    numberHelper.validate.restore()
  })

  QUnit.module('.isExcused', () => {
    test('returns true when given "EX"', () => {
      strictEqual(GradeFormatHelper.isExcused('EX'), true)
    })

    test('returns false when given point values', () => {
      strictEqual(GradeFormatHelper.isExcused('7'), false)
    })

    test('returns false when given percentage values', () => {
      strictEqual(GradeFormatHelper.isExcused('7%'), false)
    })

    test('returns false when given letter grades', () => {
      strictEqual(GradeFormatHelper.isExcused('A'), false)
    })
  })

  QUnit.module('.formatPointsOutOf()', hooks => {
    let grade
    let pointsPossible

    function formatPointsOutOf() {
      return GradeFormatHelper.formatPointsOutOf(grade, pointsPossible)
    }

    hooks.beforeEach(() => {
      grade = '7'
      pointsPossible = '10'
    })

    test('returns the score and points possible as a fraction', () => {
      strictEqual(formatPointsOutOf(), '7/10')
    })

    test('rounds the score and points possible to two decimal places', () => {
      grade = '7.123'
      pointsPossible = '10.456'
      strictEqual(formatPointsOutOf(), '7.12/10.46')
    })

    test('returns null when grade is null', () => {
      grade = null
      strictEqual(formatPointsOutOf(), null)
    })

    test('returns grade if pointsPossible is null', () => {
      pointsPossible = null
      strictEqual(formatPointsOutOf(), grade)
    })
  })

  QUnit.module('.formatGradeInfo()', hooks => {
    let options
    let gradeInfo

    function formatGradeInfo() {
      return GradeFormatHelper.formatGradeInfo(gradeInfo, options)
    }

    hooks.beforeEach(() => {
      gradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
    })

    test('returns the grade when the pending grade is valid', () => {
      strictEqual(formatGradeInfo(), 'A')
    })

    test('returns the grade when the pending grade is invalid', () => {
      gradeInfo.valid = false
      strictEqual(formatGradeInfo(), 'A')
    })

    test('returns "–" (en dash) when the pending grade is null', () => {
      gradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      strictEqual(formatGradeInfo(), '–')
    })

    test('returns the given default value when the pending grade is null', () => {
      options = {defaultValue: 'default'}
      gradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      strictEqual(formatGradeInfo(), 'default')
    })

    test('returns "Excused" when the pending grade info includes excused', () => {
      gradeInfo = {enteredAs: 'excused', excused: true, grade: null, score: null, valid: true}
      strictEqual(formatGradeInfo(), 'Excused')
    })
  })

  QUnit.module('.formatSubmissionGrade', hooks => {
    let options
    let submission

    hooks.beforeEach(() => {
      options = {
        pointsPossible: 10,
        version: 'final',
      }
      submission = {
        enteredGrade: '7.8',
        enteredScore: 7.8,
        excused: false,
        grade: '6.8',
        gradingType: 'points',
        score: 6.8,
      }
    })

    test('returns "Excused" when the submission is excused', () => {
      submission.excused = true
      equal(GradeFormatHelper.formatSubmissionGrade(submission), 'Excused')
    })

    test('translates "Excused"', () => {
      submission.excused = true
      I18n.t.withArgs('Excused').returns('EXCUSED')
      equal(GradeFormatHelper.formatSubmissionGrade(submission), 'EXCUSED')
    })

    test('formats as "points" by default', () => {
      submission.score = 7.8
      equal(GradeFormatHelper.formatSubmissionGrade(submission), '7.8')
    })

    test('uses the "final" score by default', () => {
      equal(GradeFormatHelper.formatSubmissionGrade(submission), '6.8')
    })

    QUnit.module('when formatting as "points"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.formatType = 'points'
      })

      test('returns the score as a string value', () => {
        strictEqual(GradeFormatHelper.formatSubmissionGrade(submission, options), '6.8')
      })

      test('uses the "final" score when explicitly specified', () => {
        options.version = 'final'
        strictEqual(GradeFormatHelper.formatSubmissionGrade(submission, options), '6.8')
      })

      test('optionally uses the "entered" score', () => {
        options.version = 'entered'
        strictEqual(GradeFormatHelper.formatSubmissionGrade(submission, options), '7.8')
      })

      test('uses the "final" score when given an unknown version', () => {
        options.version = 'unknown'
        strictEqual(GradeFormatHelper.formatSubmissionGrade(submission, options), '6.8')
      })

      test('rounds scores to two decimal places', () => {
        submission.score = 7.321
        strictEqual(GradeFormatHelper.formatSubmissionGrade(submission, options), '7.32')
      })

      test('rounds scores to the nearest', () => {
        submission.score = 7.325
        strictEqual(GradeFormatHelper.formatSubmissionGrade(submission, options), '7.33')
      })

      test('returns "–" (en dash) when the score is null', () => {
        submission.score = null
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '–')
      })

      test('returns "–" (en dash) for the "entered" version when the entered score is null', () => {
        submission.enteredScore = null
        options.version = 'entered'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '–')
      })

      test('returns the given default value for "final" when the final score is null', () => {
        submission.score = null
        options = {...options, version: 'final', defaultValue: 'default'}
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'default')
      })

      test('returns the given default value for "entered" when the entered score is null', () => {
        submission.enteredScore = null
        options = {...options, version: 'entered', defaultValue: 'default'}
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'default')
      })
    })

    QUnit.module('when formatting as "percentage"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.formatType = 'percent'
      })

      test('divides the score from the assignment points possible', () => {
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '68%')
      })

      test('avoids floating point calculation issues when computing the percent', () => {
        submission.score = 946.65
        options.pointsPossible = 1000
        const floatingPointResult = (946.65 / 1000) * 100
        strictEqual(floatingPointResult, 94.66499999999999)
        strictEqual(GradeFormatHelper.formatSubmissionGrade(submission, options), '94.67%')
      })

      test('uses the "final" score when explicitly specified', () => {
        options.version = 'final'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '68%')
      })

      test('optionally uses the "entered" score', () => {
        options.version = 'entered'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '78%')
      })

      test('uses the "final" score when given an unknown version', () => {
        options.version = 'unknown'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '68%')
      })

      test('rounds percentages to two decimal places', () => {
        submission.score = 7.8321
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '78.32%')
      })

      test('rounds percentages to the nearest two places', () => {
        submission.score = 7.8835 // example specifically requires correct rounding
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '78.84%')
      })

      test('returns "–" (en dash) when the score is null', () => {
        submission.score = null
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '–')
      })

      test('returns "–" (en dash) for the "entered" version when the entered score is null', () => {
        submission.enteredScore = null
        options.version = 'entered'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '–')
      })

      test('uses the score as the percentage when the assignment has no points possible', () => {
        options.pointsPossible = 0
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '6.8%')
      })

      test('optionally uses the "entered" score when using the score as the percentage', () => {
        options.pointsPossible = null
        options.version = 'entered'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '7.8%')
      })

      test('rounds the score percentage to the nearest two places', () => {
        options.pointsPossible = 0
        submission.score = 7.835 // example specifically requires correct rounding
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '7.84%')
      })
    })

    QUnit.module('when formatting as "gradingScheme"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.formatType = 'gradingScheme'
        options.gradingScheme = [
          ['A', 0.9],
          ['B', 0.8],
          ['C', 0.7],
          ['D', 0.6],
          ['F', 0.5],
        ]
      })

      test('returns the matching scheme grade for the "final" score', () => {
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'D')
      })

      test('avoids floating point calculation issues when computing the percent', () => {
        options.gradingScheme = [
          ['A', 0.94665],
          ['F', 0],
        ]
        submission.score = 946.65
        options.pointsPossible = 1000
        const floatingPointResult = (946.65 / 1000) * 100
        strictEqual(floatingPointResult, 94.66499999999999)
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'A')
      })

      test('uses the "final" score when explicitly specified', () => {
        options.version = 'final'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'D')
      })

      test('optionally uses the "entered" score', () => {
        options.version = 'entered'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'C')
      })

      test('uses the "final" score when given an unknown version', () => {
        options.version = 'unknown'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'D')
      })

      test('returns "–" (en dash) when the score is null', () => {
        submission.score = null
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '–')
      })

      test('returns "–" (en dash) for the "entered" version when the entered score is null', () => {
        submission.enteredScore = null
        options.version = 'entered'
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), '–')
      })
    })

    QUnit.module(
      'when formatting as "gradingScheme" for an assignment with no points possible',
      contextHooks => {
        contextHooks.beforeEach(() => {
          options.formatType = 'gradingScheme'
          options.gradingScheme = [
            ['A', 0.9],
            ['B', 0.8],
            ['C', 0.7],
            ['D', 0.6],
            ['F', 0.5],
          ]
          options.pointsPossible = 0
        })

        test('returns the "final" grade when the submission has been graded', () => {
          submission.enteredGrade = 'B'
          submission.enteredScore = 7.8
          submission.grade = 'C'
          submission.score = 6.8
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'C')
        })

        test('optionally uses the "entered" grade', () => {
          options.version = 'entered'
          submission.enteredGrade = 'B'
          submission.enteredScore = 7.8
          submission.grade = 'C'
          submission.score = 6.8
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'B')
        })

        test('returns a matching grading scheme grade when the submission has not explicitly graded', () => {
          submission.enteredGrade = null
          submission.enteredScore = 78
          submission.grade = null
          submission.score = 68
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'D')
        })

        test('optionally uses the "entered" score when resorting to a matching grading scheme grade', () => {
          options.version = 'entered'
          submission.enteredGrade = null
          submission.enteredScore = 78
          submission.grade = null
          submission.score = 68
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'C')
        })

        test('typically results in an arbitrarily bad grade when resorting to a matching grading scheme grade', () => {
          // the score might have been a small point value, which simply converts
          // to a small percentage when comparing to the grading scheme
          submission.enteredGrade = null
          submission.enteredScore = 7.8 // 7.8%
          submission.grade = null
          submission.score = 6.8 // 6.8%
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'F')
        })
      }
    )

    QUnit.module('when formatting as "passFail"', contextHooks => {
      contextHooks.beforeEach(() => {
        options.formatType = 'passFail'
      })

      test('returns "complete" when the "final" score is not zero', () => {
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Complete')
      })

      test('returns "incomplete" when the "final" score is zero', () => {
        submission.score = 0
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Incomplete')
      })

      test('uses the "final" score when explicitly specified', () => {
        options.version = 'final'
        submission.score = 0
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Incomplete')
      })

      test('optionally uses the "entered" score', () => {
        options.version = 'entered'
        submission.score = 0 // "final" score is made "incomplete"
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Complete')
      })

      test('uses the "final" score when given an unknown version', () => {
        options.version = 'unknown'
        submission.score = 0 // "final" score is made "incomplete"
        equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Incomplete')
      })
    })

    QUnit.module(
      'when formatting as "passFail" for an assignment with no points possible',
      contextHooks => {
        contextHooks.beforeEach(() => {
          options.formatType = 'passFail'
          options.pointsPossible = 0
          submission.enteredGrade = 'complete'
          submission.enteredScore = 10
          submission.grade = 'incomplete'
          submission.score = 0
        })

        test('returns "Complete" for a "complete" grade when using the "final" grade', () => {
          submission.grade = 'complete'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Complete')
        })

        test('returns "Complete" for a "pass" grade when using the "final" grade', () => {
          submission.grade = 'pass'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Complete')
        })

        test('returns "Incomplete" for a "incomplete" grade when using the "final" grade', () => {
          submission.grade = 'incomplete'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Incomplete')
        })

        test('returns "Incomplete" for a "fail" grade when using the "final" grade', () => {
          submission.grade = 'fail'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Incomplete')
        })

        test('returns "Complete" for a "complete" grade when using the "entered" grade', () => {
          options.version = 'entered'
          submission.enteredGrade = 'complete'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Complete')
        })

        test('returns "Complete" for a "pass" grade when using the "entered" grade', () => {
          options.version = 'entered'
          submission.enteredGrade = 'pass'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Complete')
        })

        test('returns "Incomplete" for a "incomplete" grade when using the "entered" grade', () => {
          options.version = 'entered'
          submission.enteredGrade = 'incomplete'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Incomplete')
        })

        test('returns "Incomplete" for a "fail" grade when using the "entered" grade', () => {
          options.version = 'entered'
          submission.enteredGrade = 'fail'
          equal(GradeFormatHelper.formatSubmissionGrade(submission, options), 'Incomplete')
        })
      }
    )
  })

  QUnit.module('.formatGrade() with Restrict_quantitative_data', () => {
    const scheme = [
      ['A', 0.9],
      ['B', 0.8],
      ['C', 0.7],
      ['D', 0.6],
      ['F', 0.5],
    ]

    const defaultProps = ({
      pointsPossible = 100,
      restrict_quantitative_data = true,
      score = null,
      grading_scheme = scheme,
    } = {}) => ({
      pointsPossible,
      restrict_quantitative_data,
      grading_scheme,
      score,
    })

    function formatGrade(grade, options = defaultProps()) {
      return GradeFormatHelper.formatGrade(grade, options)
    }

    test('returns the set grade value if it is already a letter_grade', () => {
      strictEqual(formatGrade('C+'), 'C+')
    })

    test('returns the set grade value if score and points possible are 0', () => {
      const gradeOptions = defaultProps({score: 0, pointsPossible: 0})
      strictEqual(formatGrade('C+', gradeOptions), 'C+')
    })

    test('returns the correct value for complete/incomplete grade', () => {
      const gradeOptions = defaultProps({score: 10, pointsPossible: 0})
      strictEqual(formatGrade('complete', gradeOptions), 'complete')
    })

    test('returns excused if the grade is excused but graded', () => {
      const gradeOptions = defaultProps({score: 50})
      strictEqual(formatGrade('EX', gradeOptions), 'Excused')
    })

    test('returns null if points possible is 0, and grade is null', () => {
      const gradeOptions = defaultProps({score: null, pointsPossible: 0})
      strictEqual(formatGrade(null, gradeOptions), null)
    })

    test('returns A if points possible is 0, and the score is greater than 0', () => {
      const gradeOptions = defaultProps({score: 1, pointsPossible: 0})
      strictEqual(formatGrade('1', gradeOptions), 'A')
    })

    test('converts percentage to letter-grade', () => {
      const gradeOptions = defaultProps({score: 8.5, pointsPossible: 10})
      strictEqual(formatGrade('85%', gradeOptions), 'B')
    })

    test('returns the correct grading scheme based on points and score', () => {
      const gradeOptions = defaultProps({score: 50})
      strictEqual(formatGrade('50', gradeOptions), 'F')
      gradeOptions.score = 60
      strictEqual(formatGrade('60', gradeOptions), 'D')
      gradeOptions.score = 70
      strictEqual(formatGrade('70', gradeOptions), 'C')
      gradeOptions.score = 80
      strictEqual(formatGrade('80', gradeOptions), 'B')
      gradeOptions.score = 90
      strictEqual(formatGrade('90', gradeOptions), 'A')
    })

    test('returns the correct letter grade based on different points possible', () => {
      const gradeOptions = defaultProps({score: 5, pointsPossible: 3})
      strictEqual(formatGrade('5', gradeOptions), 'A')
    })
  })
})
