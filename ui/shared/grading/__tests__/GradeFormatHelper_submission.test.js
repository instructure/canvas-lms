/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import GradeFormatHelper from '../GradeFormatHelper'

const I18n = createI18nScope('sharedGradeFormatHelper')

describe('GradeFormatHelper.formatSubmissionGrade', () => {
  let options
  let submission
  const translateString = I18n.t

  beforeEach(() => {
    jest.spyOn(numberHelper, 'validate').mockImplementation(val => !Number.isNaN(parseFloat(val)))
    jest.spyOn(I18n.constructor.prototype, 't').mockImplementation(translateString)

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

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('returns "Excused" when the submission is excused', () => {
    submission.excused = true
    expect(GradeFormatHelper.formatSubmissionGrade(submission)).toBe('Excused')
  })

  it('translates "Excused"', () => {
    submission.excused = true
    jest.spyOn(I18n, 't').mockReturnValue('EXCUSED')
    expect(GradeFormatHelper.formatSubmissionGrade(submission)).toBe('EXCUSED')
  })

  it('formats as "points" by default', () => {
    submission.score = 7.8
    expect(GradeFormatHelper.formatSubmissionGrade(submission)).toBe('7.8')
  })

  it('uses the "final" score by default', () => {
    expect(GradeFormatHelper.formatSubmissionGrade(submission)).toBe('6.8')
  })

  describe('when formatting as "points"', () => {
    beforeEach(() => {
      options.formatType = 'points'
    })

    it('returns the score as a string value', () => {
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('6.8')
    })

    it('uses the "final" score when explicitly specified', () => {
      options.version = 'final'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('6.8')
    })

    it('optionally uses the "entered" score', () => {
      options.version = 'entered'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('7.8')
    })

    it('uses the "final" score when given an unknown version', () => {
      options.version = 'unknown'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('6.8')
    })

    it('rounds scores to two decimal places', () => {
      submission.score = 7.321
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('7.32')
    })

    it('rounds scores to the nearest', () => {
      submission.score = 7.325
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('7.33')
    })

    it('returns "–" (en dash) when the score is null', () => {
      submission.score = null
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('–')
    })

    it('returns "–" (en dash) for the "entered" version when the entered score is null', () => {
      submission.enteredScore = null
      options.version = 'entered'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('–')
    })

    it('returns the given default value for "final" when the final score is null', () => {
      submission.score = null
      options = {...options, version: 'final', defaultValue: 'default'}
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('default')
    })

    it('returns the given default value for "entered" when the entered score is null', () => {
      submission.enteredScore = null
      options = {...options, version: 'entered', defaultValue: 'default'}
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('default')
    })
  })

  describe('when formatting as "percentage"', () => {
    beforeEach(() => {
      options.formatType = 'percent'
    })

    it('divides the score from the assignment points possible', () => {
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('68%')
    })

    it('avoids floating point calculation issues when computing the percent', () => {
      submission.score = 946.65
      options.pointsPossible = 1000
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('94.67%')
    })

    it('uses the "final" score when explicitly specified', () => {
      options.version = 'final'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('68%')
    })

    it('optionally uses the "entered" score', () => {
      options.version = 'entered'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('78%')
    })

    it('uses the "final" score when given an unknown version', () => {
      options.version = 'unknown'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('68%')
    })

    it('rounds percentages to two decimal places', () => {
      submission.score = 7.8321
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('78.32%')
    })

    it('rounds percentages to the nearest two places', () => {
      submission.score = 7.8835
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('78.84%')
    })

    it('returns "–" (en dash) when the score is null', () => {
      submission.score = null
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('–')
    })

    it('returns "–" (en dash) for the "entered" version when the entered score is null', () => {
      submission.enteredScore = null
      options.version = 'entered'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('–')
    })

    it('uses the score as the percentage when the assignment has no points possible', () => {
      options.pointsPossible = 0
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('6.8%')
    })

    it('optionally uses the "entered" score when using the score as the percentage', () => {
      options.pointsPossible = null
      options.version = 'entered'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('7.8%')
    })

    it('rounds the score percentage to the nearest two places', () => {
      options.pointsPossible = 0
      submission.score = 7.835
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('7.84%')
    })
  })

  describe('when formatting as "gradingScheme"', () => {
    beforeEach(() => {
      options.formatType = 'gradingScheme'
      options.gradingScheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0.5],
      ]
    })

    it('returns the matching scheme grade for the "final" score', () => {
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('D')
    })

    it('avoids floating point calculation issues when computing the percent', () => {
      options.gradingScheme = [
        ['A', 0.94665],
        ['F', 0],
      ]
      submission.score = 946.65
      options.pointsPossible = 1000
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('A')
    })

    it('uses the "final" score when explicitly specified', () => {
      options.version = 'final'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('D')
    })

    it('optionally uses the "entered" score', () => {
      options.version = 'entered'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('C')
    })

    it('uses the "final" score when given an unknown version', () => {
      options.version = 'unknown'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('D')
    })

    it('returns "–" (en dash) when the score is null', () => {
      submission.score = null
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('–')
    })

    it('returns "–" (en dash) for the "entered" version when the entered score is null', () => {
      submission.enteredScore = null
      options.version = 'entered'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('–')
    })
  })

  describe('when formatting as "gradingScheme" for an assignment with no points possible', () => {
    beforeEach(() => {
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

    it('returns the "final" grade when the submission has been graded', () => {
      submission.enteredGrade = 'B'
      submission.enteredScore = 7.8
      submission.grade = 'C'
      submission.score = 6.8
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('C')
    })

    it('optionally uses the "entered" grade', () => {
      options.version = 'entered'
      submission.enteredGrade = 'B'
      submission.enteredScore = 7.8
      submission.grade = 'C'
      submission.score = 6.8
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('B')
    })

    it('returns a matching grading scheme grade when the submission has not explicitly graded', () => {
      submission.enteredGrade = null
      submission.enteredScore = 78
      submission.grade = null
      submission.score = 68
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('D')
    })

    it('optionally uses the "entered" score when resorting to a matching grading scheme grade', () => {
      options.version = 'entered'
      submission.enteredGrade = null
      submission.enteredScore = 78
      submission.grade = null
      submission.score = 68
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('C')
    })

    it('typically results in an arbitrarily bad grade when resorting to a matching grading scheme grade', () => {
      submission.enteredGrade = null
      submission.enteredScore = 7.8
      submission.grade = null
      submission.score = 6.8
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('F')
    })
  })

  describe('when formatting as "passFail"', () => {
    beforeEach(() => {
      options.formatType = 'passFail'
    })

    it('returns "complete" when the "final" score is not zero', () => {
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Complete')
    })

    it('returns "incomplete" when the "final" score is zero', () => {
      submission.score = 0
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Incomplete')
    })

    it('uses the "final" score when explicitly specified', () => {
      options.version = 'final'
      submission.score = 0
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Incomplete')
    })

    it('optionally uses the "entered" score', () => {
      options.version = 'entered'
      submission.score = 0
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Complete')
    })

    it('uses the "final" score when given an unknown version', () => {
      options.version = 'unknown'
      submission.score = 0
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Incomplete')
    })
  })

  describe('when formatting as "passFail" for an assignment with no points possible', () => {
    beforeEach(() => {
      options.formatType = 'passFail'
      options.pointsPossible = 0
      submission.enteredGrade = 'complete'
      submission.enteredScore = 10
      submission.grade = 'incomplete'
      submission.score = 0
    })

    it('returns "Complete" for a "complete" grade when using the "final" grade', () => {
      submission.grade = 'complete'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Complete')
    })

    it('returns "Complete" for a "pass" grade when using the "final" grade', () => {
      submission.grade = 'pass'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Complete')
    })

    it('returns "Incomplete" for a "incomplete" grade when using the "final" grade', () => {
      submission.grade = 'incomplete'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Incomplete')
    })

    it('returns "Incomplete" for a "fail" grade when using the "final" grade', () => {
      submission.grade = 'fail'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Incomplete')
    })

    it('returns "Complete" for a "complete" grade when using the "entered" grade', () => {
      options.version = 'entered'
      submission.enteredGrade = 'complete'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Complete')
    })

    it('returns "Complete" for a "pass" grade when using the "entered" grade', () => {
      options.version = 'entered'
      submission.enteredGrade = 'pass'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Complete')
    })

    it('returns "Incomplete" for a "incomplete" grade when using the "entered" grade', () => {
      options.version = 'entered'
      submission.enteredGrade = 'incomplete'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Incomplete')
    })

    it('returns "Incomplete" for a "fail" grade when using the "entered" grade', () => {
      options.version = 'entered'
      submission.enteredGrade = 'fail'
      expect(GradeFormatHelper.formatSubmissionGrade(submission, options)).toBe('Incomplete')
    })
  })
})
