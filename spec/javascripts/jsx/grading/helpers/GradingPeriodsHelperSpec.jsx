define([
  'jsx/grading/helpers/GradingPeriodsHelper'
], (GradingPeriodsHelper) => {
  const DATE_IN_FIRST_PERIOD = new Date('July 15, 2015');
  const DATE_IN_LAST_PERIOD = new Date('Sep 15, 2015');
  const DATE_OUTSIDE_OF_ANY_PERIOD = new Date('Jun 15, 2015');

  function generateGradingPeriods () {
    return [{
      id: '101',
      startDate: new Date('2015-07-01T06:00:00Z'),
      endDate: new Date('2015-08-31T06:00:00Z'),
      title: 'Closed Period',
      closeDate: new Date('2015-08-31T06:00:00Z'),
      isLast: false,
      isClosed: true
    }, {
      id: '102',
      startDate: new Date('2015-09-01T06:00:00Z'),
      endDate: new Date('2015-10-31T06:00:00Z'),
      title: 'Period',
      closeDate: new Date('2015-11-15T06:00:00Z'),
      isLast: true,
      isClosed: false
    }];
  }

  module('GradingPeriodsHelper#new');

  test('throws an error if any dates on the grading periods are Strings', function () {
    const gradingPeriods = generateGradingPeriods();
    gradingPeriods[0].startDate = '2015-07-01T06:00:00Z';
    throws(() => { new GradingPeriodsHelper(gradingPeriods) });
  });

  test('throws an error if any dates on the grading periods are null', function () {
    const gradingPeriods = generateGradingPeriods();
    gradingPeriods[0].startDate = null;
    throws(() => { new GradingPeriodsHelper(gradingPeriods) });
  });

  test('throws an error if grading periods are not passed in', function () {
    throws(() => { new GradingPeriodsHelper() });
  });

  module('GradingPeriodsHelper.isAllGradingPeriods');

  test('returns true if the ID is the string "0"', function () {
    equal(GradingPeriodsHelper.isAllGradingPeriods('0'), true);
  });

  test('returns false if the ID is a string other than "0"', function () {
    equal(GradingPeriodsHelper.isAllGradingPeriods('42'), false);
  });

  test('throws the error if the ID is not a string', function () {
    throws(() => { GradingPeriodsHelper.isAllGradingPeriods(0) });
  });

  module('GradingPeriodsHelper#gradingPeriodForDueAt', {
    setup() {
      this.gradingPeriods = generateGradingPeriods();
      this.helper = new GradingPeriodsHelper(this.gradingPeriods);
    }
  });

  test('returns the grading period that the given due at falls in', function () {
    const period = this.helper.gradingPeriodForDueAt(DATE_IN_FIRST_PERIOD);
    equal(period, this.gradingPeriods[0]);
  });

  test('returns the last grading period if the due at is null', function () {
    const period = this.helper.gradingPeriodForDueAt(null);
    equal(period, this.gradingPeriods[1]);
  });

  test('returns null if the given due at does not fall in any grading period', function () {
    const period = this.helper.gradingPeriodForDueAt(DATE_OUTSIDE_OF_ANY_PERIOD);
    deepEqual(period, null);
  });

  test('throws an error if the due at is a String', function () {
    throws(() => { this.helper.gradingPeriodForDueAt('Jan 20, 2015') });
  });

  module('GradingPeriodsHelper#isDateInGradingPeriod', {
    setup() {
      const gradingPeriods = generateGradingPeriods();
      this.helper = new GradingPeriodsHelper(gradingPeriods);
      this.firstPeriod = gradingPeriods[0];
      this.lastPeriod = gradingPeriods[1];
    }
  });

  test('returns true if the given date falls in the grading period', function () {
    equal(this.helper.isDateInGradingPeriod(DATE_IN_FIRST_PERIOD, this.firstPeriod.id), true);
  });

  test('returns true if the given date exactly matches the grading period start date', function () {
    const exactStartDate = this.firstPeriod.startDate;
    equal(this.helper.isDateInGradingPeriod(exactStartDate, this.firstPeriod.id), false);
  });

  test('returns false if the given date exactly matches the grading period end date', function () {
    const exactEndDate = this.firstPeriod.endDate;
    equal(this.helper.isDateInGradingPeriod(exactEndDate, this.firstPeriod.id), true);
  });

  test('returns false if the given date falls outside the grading period', function () {
    equal(this.helper.isDateInGradingPeriod(DATE_OUTSIDE_OF_ANY_PERIOD, this.firstPeriod.id), false);
  });

  test('returns true if the given date is null and the grading period is the last period', function () {
    equal(this.helper.isDateInGradingPeriod(null, this.lastPeriod.id), true);
  });

  test('returns false if the given date is null and the grading period is not the last period', function () {
    equal(this.helper.isDateInGradingPeriod(null, this.firstPeriod.id), false);
  });

  test('throws an error if the given date is a String', function () {
    throws(() => { this.helper.isDateInGradingPeriod('Jan 20, 2015', this.firstPeriod.id) });
  });

  test('throws an error if no grading period exists with the given id', function () {
    throws(() => { this.helper.isDateInGradingPeriod(DATE_IN_FIRST_PERIOD, '222') });
  });

  module('GradingPeriodsHelper#earliestValidDueDate', {
    setup() {
      this.gradingPeriods = generateGradingPeriods();
      this.firstPeriod = this.gradingPeriods[0];
      this.secondPeriod = this.gradingPeriods[1];
    }
  });

  test('returns the start date of the earliest open grading period', function () {
    let earliestDate = new GradingPeriodsHelper(this.gradingPeriods).earliestValidDueDate;
    equal(earliestDate, this.secondPeriod.startDate);
    this.firstPeriod.isClosed = false;
    earliestDate = new GradingPeriodsHelper(this.gradingPeriods).earliestValidDueDate;
    equal(earliestDate, this.firstPeriod.startDate);
  });

  test('returns null if there are no open grading periods', function () {
    this.secondPeriod.isClosed = true;
    const earliestDate = new GradingPeriodsHelper(this.gradingPeriods).earliestValidDueDate;
    equal(earliestDate, null);
  });

  module('GradingPeriodsHelper#isDateInClosedGradingPeriod', {
    setup () {
      const gradingPeriods = generateGradingPeriods();
      this.helper = new GradingPeriodsHelper(gradingPeriods);
    }
  });

  test('returns true if a date falls in a closed grading period', function () {
    equal(this.helper.isDateInClosedGradingPeriod(DATE_IN_FIRST_PERIOD), true);
  });

  test('returns false if a date falls in an open grading period', function () {
    equal(this.helper.isDateInClosedGradingPeriod(DATE_IN_LAST_PERIOD), false);
  });

  test('returns false if a date does not fall in any grading period', function () {
    equal(this.helper.isDateInClosedGradingPeriod(DATE_OUTSIDE_OF_ANY_PERIOD), false);
  });
});
