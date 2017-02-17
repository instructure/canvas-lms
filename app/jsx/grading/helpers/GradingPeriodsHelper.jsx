define([
  'underscore'
  ], function(_) {

  function validateDate(date, nullAllowed = false) {
    let valid = _.isDate(date);
    if (nullAllowed && !valid) {
      valid = date === null;
    }

    if (!valid) throw new Error(`\`${date}\` must be a Date or null`);
  }

  function validateGradingPeriodDates(gradingPeriods) {
    if (gradingPeriods == null) throw new Error(`\'${gradingPeriods}\' must be an array or object`);

    const dates = ["startDate", "endDate", "closeDate"];
    const periods = _.isArray(gradingPeriods) ? gradingPeriods : [gradingPeriods];
    _.each(periods, function(period) {
      _.each(dates, date => validateDate(period[date]));
    });

    return periods;
  }

  function validatePeriodID(id) {
    const valid = _.isString(id);
    if (!valid) throw new Error(`Grading period id \`${id}\` must be a String`);
  }

  class GradingPeriodsHelper {
    constructor(gradingPeriods) {
      this.gradingPeriods = validateGradingPeriodDates(gradingPeriods);
    }

    static isAllGradingPeriods(periodID) {
      validatePeriodID(periodID);

      return periodID === "0";
    }

    get earliestValidDueDate() {
      const orderedPeriods = _.sortBy(this.gradingPeriods, "startDate");
      const earliestOpenPeriod = _.find(orderedPeriods, { isClosed: false });
      if (earliestOpenPeriod) {
        return earliestOpenPeriod.startDate;
      } else {
        return null;
      }
    }

    gradingPeriodForDueAt(dueAt) {
      validateDate(dueAt, true);

      return _.find(this.gradingPeriods, (period) => {
        return this.isDateInGradingPeriod(dueAt, period.id, false);
      }) || null;
    }

    isDateInGradingPeriod(date, gradingPeriodID, runValidations=true) {
      if (runValidations) {
        validateDate(date, true);
        validatePeriodID(gradingPeriodID);
      }

      const gradingPeriod = _.find(this.gradingPeriods, { id: gradingPeriodID });
      if (!gradingPeriod) throw new Error(`No grading period has id \`${gradingPeriodID}\``);

      if (date === null) {
        return gradingPeriod.isLast;
      } else {
        return gradingPeriod.startDate < date && date <= gradingPeriod.endDate;
      }
    }

    isDateInClosedGradingPeriod(date) {
      const period = this.gradingPeriodForDueAt(date);
      return !!period && period.isClosed;
    }
  }

  return GradingPeriodsHelper;
});
