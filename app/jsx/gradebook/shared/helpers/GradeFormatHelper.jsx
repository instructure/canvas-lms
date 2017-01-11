define([
  'i18n!gradebook',
  'jsx/shared/helpers/numberHelper',
  'compiled/util/round'
], (I18n, numberHelper, round) => {
  function shouldFormatGrade (grade) {
    return /^\d+\.?\d*%?$/.test(grade);
  }

  class GradeFormatHelper {
    /**
     * Returns given grade rounded to two decimal places and formatted with I18n
     * if it is a point or percent grade.
     * If grade is undefined or null empty string is returned.
     * Other grades are returned as given.
     */
    formatGrade (grade) {
      let formattedGrade;

      if (grade === undefined || grade === null) {
        return '';
      }

      formattedGrade = grade.toString();

      if (shouldFormatGrade(grade)) {
        const isPercent = /%/g.test(formattedGrade);

        formattedGrade = formattedGrade.replace(/%/g, '');
        formattedGrade = round(numberHelper.parse(formattedGrade), 2);
        formattedGrade = I18n.n(formattedGrade, { percentage: isPercent });
      }

      return formattedGrade;
    }
  }

  return new GradeFormatHelper();
});
