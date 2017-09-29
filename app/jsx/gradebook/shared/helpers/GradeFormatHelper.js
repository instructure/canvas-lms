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

import I18n from 'i18n!gradebook'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import round from 'compiled/util/round'

const POINTS = 'points';
const PERCENT = 'percent';
const COMPLETION = 'completion';

function isCompletion (grade, gradeType) {
  if (gradeType) {
    return gradeType === COMPLETION;
  }

  return grade === 'complete' || grade === 'incomplete';
}

function isPercent (grade, gradeType) {
  if (gradeType) {
    return gradeType === PERCENT;
  }

  return /%/g.test(grade);
}

function shouldFormatGradingType (gradingType) {
  return gradingType === POINTS || gradingType === PERCENT || gradingType === COMPLETION;
}

function shouldFormatGrade (grade, gradingType) {
  if (gradingType) {
    return shouldFormatGradingType(gradingType);
  }

  return typeof grade === 'number' || isCompletion(grade);
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
   *    being formatted. A value of 'completion' will result in internationalization.
   *    Any other value will result in the grade not being formatted.
   *  precision {number} - If present grade will be rounded to given precision. Default is two decimals.
   *  defaultValue - If present will be the return value when the grade is undefined, null, or empty string.
   *
   * @return {string} Given grade rounded to two decimal places and formatted with I18n
   * if it is a point or percent grade.
   */
  formatGrade (grade, options = {}) {
    let formattedGrade = grade;

    if (grade == null || grade === '') {
      return ('defaultValue' in options) ? options.defaultValue : grade;
    }

    const parsedGrade = GradeFormatHelper.parseGrade(grade, options);

    if (shouldFormatGrade(parsedGrade, options.gradingType)) {
      if (isCompletion(parsedGrade, options.gradingType)) {
        formattedGrade = parsedGrade === 'complete' ? I18n.t('complete') : I18n.t('incomplete');
      } else {
        const roundedGrade = round(parsedGrade, options.precision || 2);
        formattedGrade = I18n.n(roundedGrade, { percentage: isPercent(grade, options.gradingType) });
      }
    }

    return formattedGrade;
  },

  /**
   * Given a localized point or percentage grade string,
   * returns delocalized point or percentage string.
   * Otherwise, returns input.
   */
  delocalizeGrade (localizedGrade) {
    if (localizedGrade === undefined ||
        localizedGrade === null ||
        typeof localizedGrade !== 'string') {
      return localizedGrade;
    }

    const delocalizedGrade = numberHelper.parse(localizedGrade.replace('%', ''));

    if (isNaN(delocalizedGrade)) {
      return localizedGrade;
    }

    return delocalizedGrade + (/%/g.test(localizedGrade) ? '%' : '');
  },

  parseGrade (grade, options = {}) {
    let parsedGrade;

    if (grade == null || grade === '' || typeof grade === 'number') {
      return grade;
    }

    const gradeNoPercent = grade.replace('%', '')
    if ( 'delocalize' in options && !options.delocalize && !isNaN(gradeNoPercent) ) {
      parsedGrade = parseFloat(gradeNoPercent);
    } else {
      parsedGrade = numberHelper.parse(gradeNoPercent);
    }

    if (isNaN(parsedGrade)) {
      return grade;
    }

    return parsedGrade;
  }
};

export default GradeFormatHelper
