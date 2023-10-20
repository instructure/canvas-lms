// @ts-nocheck
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
import round from '@canvas/round'
import numberHelper from '@canvas/i18n/numberHelper'
import {scoreToPercentage} from './GradeCalculationHelper'
import {scoreToGrade} from '@instructure/grading-utils'
import type {FormatGradeOptions, SubmissionData} from './grading.d'

const I18n = useI18nScope('sharedGradeFormatHelper')

const LETTER_GRADE = 'letter_grade'
const POINTS = 'points'
const PERCENT = 'percent'
const PASS_FAIL = 'pass_fail'
const GPA_SCALE = 'gpa_scale'
const POINTS_OUT_OF_FRACTION = 'points_out_of_fraction'

const PASS_GRADES = ['complete', 'pass']
const FAIL_GRADES = ['incomplete', 'fail']

const UNGRADED = '–'
const QUANTITATIVE_GRADING_TYPES = [POINTS, PERCENT, GPA_SCALE]
const QUALITATIVE_GRADING_TYPES = ['pass_fail', 'letter_grade']

function replaceDashWithMinus(grade) {
  if (typeof grade !== 'string') return grade

  return grade.replace(/(.+)-$/, '$1−')
}

function isPassFail(grade, gradeType: null | string = null) {
  if (gradeType) {
    return gradeType === PASS_FAIL
  }

  return PASS_GRADES.includes(grade) || FAIL_GRADES.includes(grade)
}

function isPercent(grade, gradeType) {
  if (gradeType) {
    return gradeType === PERCENT
  }

  return /%/g.test(grade)
}

function isExcused(grade) {
  return grade === 'EX'
}

function formatPointsOutOf(grade, pointsPossible) {
  if (grade == null || grade === '') {
    return grade
  }

  if (pointsPossible == null || pointsPossible === '') {
    return grade
  }

  const numberOptions = {precision: 2, strip_insignificant_zeros: true}
  let score = UNGRADED
  if (grade != null) {
    score = I18n.n(grade, numberOptions)
  }
  const pointsPossibleTranslated = I18n.n(pointsPossible, numberOptions)
  return I18n.t('%{score}/%{pointsPossibleTranslated}', {pointsPossibleTranslated, score})
}

function normalizeCompleteIncompleteGrade(grade) {
  if (PASS_GRADES.includes(grade)) {
    return 'complete'
  }
  if (FAIL_GRADES.includes(grade)) {
    return 'incomplete'
  }
  return null
}

function shouldFormatGradingType(gradingType) {
  return (
    gradingType === POINTS ||
    gradingType === PERCENT ||
    gradingType === PASS_FAIL ||
    gradingType === LETTER_GRADE
  )
}

function shouldFormatGrade(grade, gradingType) {
  if (gradingType) {
    return shouldFormatGradingType(gradingType)
  }

  return typeof grade === 'number' || isPassFail(grade)
}

function excused() {
  return I18n.t('Excused')
}

function formatPointsGrade(score) {
  return I18n.n(round(score, 2), {precision: 2, strip_insignificant_zeros: true})
}

function formatPercentageGrade(score, options) {
  const percent = options.pointsPossible ? scoreToPercentage(score, options.pointsPossible) : score
  return I18n.n(round(percent, 2), {
    percentage: true,
    precision: 2,
    strip_insignificant_zeros: true,
  })
}

function formatGradingSchemeGrade(score, grade, options = {}) {
  let formattedGrade
  if (options?.restrict_quantitative_data && options.pointsPossible === 0 && score >= 0) {
    formattedGrade = scoreToGrade(100, options.gradingScheme)
  } else if (options.pointsPossible) {
    const percent = scoreToPercentage(score, options.pointsPossible)
    formattedGrade = scoreToGrade(percent, options.gradingScheme)
  } else if (grade != null) {
    formattedGrade = grade
  } else {
    formattedGrade = scoreToGrade(score, options.gradingScheme)
  }

  return replaceDashWithMinus(formattedGrade)
}

function formatCompleteIncompleteGrade(score, grade, options) {
  let passed = false
  if (options.pointsPossible) {
    passed = score > 0
  } else {
    passed = PASS_GRADES.includes(grade)
  }
  return passed ? I18n.t('Complete') : I18n.t('Incomplete')
}

function formatGradeInfo(gradeInfo, options: {defaultValue?: string} = {}) {
  if (gradeInfo.excused) {
    return excused()
  }

  if (gradeInfo.grade == null) {
    return options.defaultValue != null ? options.defaultValue : UNGRADED
  }

  return gradeInfo.grade
}

const GradeFormatHelper = {
  /**
   * Returns given grade rounded to two decimal places and formatted with I18n
   * if it is a point or percent grade.
   * If grade is undefined, null, or empty string, the grade is returned as is.
   *
   * @param {string|number|undefined|null} grade - Grade to be formatted.
   * @param {object} options - An optional hash of arguments. The following optional arguments are supported:
   *  gradingType {string} - If present will be used to determine whether or not to
   *    format given grade. A value of 'points' or 'percent' will result in the grade
   *    being formatted. A value of 'pass_fail' will result in internationalization.
   *    Any other value will result in the grade not being formatted.
   *  precision {number} - If present grade will be rounded to given precision. Default is two decimals.
   *  formatType {string} - formats grade based on grading type
   *    - points_out_of_fraction: if grading type is points and this format type is present the grade will
   *      show its out of score. {grade}/{pointsPossible} i.e. 5/10 1/15
   *  defaultValue - If present will be the return value when the grade is undefined, null, or empty string.
   *  score {number} - If present, will be used along with ENV.restrict_quantitative_data and the pointsPossbile option.
   *    score is used to convert quantitative grades into their letter grade equivalent, without score and pointsPossbile,
   *    quantitative grades will stay as is
   *  pointsPossible {number} - If present, used in points our of fraction formatting, and also used in conjunction
   *    with score to turn quantitative grading types into letter grade
   *
   * @return {string} Given grade rounded to two decimal places and formatted with I18n
   * if it is a point or percent grade.
   */
  formatGrade(grade, options: FormatGradeOptions = {}) {
    let formattedGrade = grade

    if (grade == null || grade === '') {
      return 'defaultValue' in options ? options.defaultValue : grade
    }

    if (isExcused(grade)) {
      return excused()
    }

    let parsedGrade = GradeFormatHelper.parseGrade(grade, options)

    if (shouldFormatGrade(parsedGrade, options.gradingType)) {
      if (isPassFail(parsedGrade, options.gradingType)) {
        parsedGrade = normalizeCompleteIncompleteGrade(parsedGrade)
        formattedGrade = parsedGrade === 'complete' ? I18n.t('complete') : I18n.t('incomplete')
      } else if (parsedGrade && options.gradingType === LETTER_GRADE) {
        formattedGrade = formatGradingSchemeGrade(null, parsedGrade)
      } else if (
        options.restrict_quantitative_data &&
        options.score != null &&
        options.pointsPossible != null
      ) {
        // at this stage, gradingType is either points or percent, or the passed grade is a number
        formattedGrade = formatGradingSchemeGrade(options.score, null, {
          gradingScheme: options.grading_scheme,
          pointsPossible: options.pointsPossible,
          restrict_quantitative_data: options.restrict_quantitative_data,
        })
      } else {
        const roundedGrade = round(parsedGrade, options.precision || 2)
        formattedGrade = I18n.n(roundedGrade, {percentage: isPercent(grade, options.gradingType)})
      }
    }
    if (
      !options.restrict_quantitative_data &&
      options.gradingType === POINTS &&
      options.formatType === POINTS_OUT_OF_FRACTION
    ) {
      formattedGrade = formatPointsOutOf(grade, options.pointsPossible)
    }
    if (
      options.restrict_quantitative_data &&
      options.score != null &&
      options.pointsPossible != null &&
      options.gradingType === GPA_SCALE
    ) {
      formattedGrade = formatGradingSchemeGrade(options.score, null, {
        gradingScheme: options.grading_scheme,
        pointsPossible: options.pointsPossible,
        restrict_quantitative_data: options.restrict_quantitative_data,
      })
    }

    if (
      options.restrict_quantitative_data &&
      options.score != null &&
      options.pointsPossible === 0 &&
      options.gradingType === 'letter_grade'
    ) {
      formattedGrade = formatGradingSchemeGrade(options.score, null, {
        gradingScheme: options.grading_scheme,
        pointsPossible: options.pointsPossible,
        restrict_quantitative_data: options.restrict_quantitative_data,
      })
    }
    return formattedGrade
  },

  /**
   * Given a localized point or percentage grade string,
   * returns delocalized point or percentage string.
   * Otherwise, returns input.
   */
  delocalizeGrade(localizedGrade) {
    if (
      localizedGrade === undefined ||
      localizedGrade === null ||
      typeof localizedGrade !== 'string'
    ) {
      return localizedGrade
    }

    const delocalizedGrade = numberHelper.parse(localizedGrade.replace('%', ''))

    if (Number.isNaN(Number(delocalizedGrade))) {
      return localizedGrade
    }

    return delocalizedGrade + (/%/g.test(localizedGrade) ? '%' : '')
  },

  parseGrade(grade, options: FormatGradeOptions = {}) {
    let parsedGrade

    if (grade == null || grade === '' || typeof grade === 'number') {
      return grade
    }

    const gradeNoPercent = grade.replace('%', '')
    if ('delocalize' in options && !options.delocalize && !Number.isNaN(Number(gradeNoPercent))) {
      parsedGrade = parseFloat(gradeNoPercent)
    } else {
      parsedGrade = numberHelper.parse(gradeNoPercent)
    }

    if (Number.isNaN(Number(parsedGrade))) {
      return grade
    }

    return parsedGrade
  },

  excused,
  isExcused,
  formatGradeInfo,
  formatPointsOutOf,

  formatSubmissionGrade(
    submission: SubmissionData,
    options: {version: string; defaultValue?: string; formatType?: string} = {version: 'final'}
  ) {
    if (submission.excused) {
      return excused()
    }

    const score = options.version === 'entered' ? submission.enteredScore : submission.score
    const grade = options.version === 'entered' ? submission.enteredGrade : submission.grade

    if (score == null) {
      return options.defaultValue != null ? options.defaultValue : UNGRADED
    }

    switch (options.formatType) {
      case 'percent':
        return formatPercentageGrade(score, options)
      case 'gradingScheme':
        return formatGradingSchemeGrade(score, grade, options)
      case 'passFail':
        return formatCompleteIncompleteGrade(score, grade, options)
      default:
        return formatPointsGrade(score)
    }
  },

  replaceDashWithMinus,
  UNGRADED,
  QUANTITATIVE_GRADING_TYPES,
  QUALITATIVE_GRADING_TYPES,
}

export default GradeFormatHelper
