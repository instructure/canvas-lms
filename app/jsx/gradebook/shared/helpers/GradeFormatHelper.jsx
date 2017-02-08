define([
  'i18n!gradebook',
  'jsx/shared/helpers/numberHelper',
  'compiled/util/round'
], (I18n, numberHelper, round) => {
  const POINTS = 'points';
  const PERCENT = 'percent';

  function shouldFormatGradingType (gradingType) {
    return gradingType === POINTS || gradingType === PERCENT;
  }

  function shouldFormatGrade (grade, gradingType) {
    if (gradingType) {
      return shouldFormatGradingType(gradingType);
    }

    return /^\d+\.?\d*%?$/.test(grade);
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
     *
     * @return {string} Given grade rounded to two decimal places and formatted with I18n
     * if it is a point or percent grade.
     */
    formatGrade (grade, opts = {}) {
      let formattedGrade;

      if (grade === undefined || grade === null || grade === '') {
        return grade;
      }

      formattedGrade = grade.toString();

      if (shouldFormatGrade(grade, opts.gradingType)) {
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

  return new GradeFormatHelper();
});
