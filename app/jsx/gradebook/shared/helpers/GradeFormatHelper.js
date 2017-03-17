/*
 * Copyright (C) 2017 Instructure, Inc.
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

function shouldFormatGradingType (gradingType) {
  return gradingType === POINTS || gradingType === PERCENT;
}

function shouldFormatGrade (grade, gradingType) {
  if (gradingType) {
    return shouldFormatGradingType(gradingType);
  }

  return numberHelper.validate(grade.replace('%', ''));
}

function isPercent (grade, gradeType) {
  if (gradeType) {
    return gradeType === PERCENT;
  }

  return /%/g.test(grade);
}

class GradeFormatHelper {
  /**
   * Returns given grade rounded to two decimal places and formatted with I18n
   * if it is a point or percent grade.
   * If grade is undefined, null, or empty string, the grade is returned as is.
   * Other grades are returned as given after calling grade.toString().
   *
   * @param {string|number|undefined|null} grade - Grade to be formatted.
   * @param {object} opts - An optional hash of arguments. The following optional arguments are supported:
   *  gradingType {string} - If present will be used to determine whether or not to
   *    format given grade. A value of 'points' or 'percent' will result in the grade
   *    being formatted. Any other value will result in the grade not being formatted.
   *  precision {number} - If present grade will be rounded to given precision. Default is two decimals.
   *  defaultValue - If present will be the return value when the grade is undefined, null, or empty string.
   *
   * @return {string} Given grade rounded to two decimal places and formatted with I18n
   * if it is a point or percent grade.
   */
  formatGrade (grade, opts = {}) {
    let formattedGrade;

    if (grade === undefined || grade === null || grade === '') {
      return Object.prototype.hasOwnProperty.call(opts, 'defaultValue') ? opts.defaultValue : grade;
    }

    formattedGrade = grade.toString();

    if (shouldFormatGrade(formattedGrade, opts.gradingType)) {
      formattedGrade = formattedGrade.replace(/%/g, '');
      formattedGrade = round(numberHelper.parse(formattedGrade), opts.precision || 2);
      formattedGrade = I18n.n(formattedGrade, { percentage: isPercent(grade, opts.gradingType) });
    }

    return formattedGrade;
  }

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
  }
}

export default new GradeFormatHelper()
