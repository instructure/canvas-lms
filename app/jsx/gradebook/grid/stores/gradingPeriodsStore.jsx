define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jsx/gradebook/grid/actions/gradingPeriodsActions',
  'jsx/gradebook/grid/stores/gradingPeriodsStore',
  'jsx/gradebook/grid/helpers/dueDateCalculator',
  'jsx/gradebook/grid/constants',
  'compiled/userSettings'
], function (Reflux, _, GradingPeriodsActions, GradingPeriodsStore,
             DueDateCalculator, GradebookConstants, userSettings) {
  var GradePeriodsStore = Reflux.createStore({

    listenables: [GradingPeriodsActions],

    selected() {
      return _.find(this.gradingPeriods.data, function(period) {
        return period.id === this.gradingPeriods.selected;
      }.bind(this));
    },

    getInitialState() {
      var allPeriodsOption, activeGradingPeriods;

      allPeriodsOption = {
        end_date: new Date().setYear(3000),
        id: '0',
        is_last: false,
        start_date: new Date().setYear(0),
        title: 'All Grading Periods'
      };

      activeGradingPeriods = GradebookConstants.active_grading_periods;

      this.gradingPeriods = {
        data: [allPeriodsOption].concat(activeGradingPeriods),
        selected: null,
        error: null
      };

      this.gradingPeriods.selected = this.gradePeriodOnLoad();
      this.trigger(this.gradingPeriods);
    },

    // handler for selecting a grading period
    onSelect(periodData) {
      var selectedPeriod, allPeriods, periodMatcher;

      allPeriods = this.gradingPeriods.data;
      periodMatcher = period => period.id === periodData.id;
      selectedPeriod = _.find(allPeriods, periodMatcher);

      if (selectedPeriod !== null && selectedPeriod !== undefined) {
        this.gradingPeriods.selected = selectedPeriod.id;
        this.trigger(this.gradingPeriods);
      }
    },

    /*
       ([Assignment], GradingPeriod) -> [Assignment]
       Given a list of assignments and a grading period, returns the assignments
       which are in the grading period
    */
    assignmentsInPeriod(assignments, period) {
      var assignmentList;

      assignmentList = _.filter(assignments, assignment =>
        this.assignmentIsInPeriod(assignment, period));

      return assignmentList;
    },

    /*
       (Assignment, GradingPeriod) -> Boolean
       Given an assignment and a grading period, checks if assignment is in the
       given grading period
    */
    assignmentIsInPeriod(assignment, period) {
      var dueDateString, assignmentDueDate, periodStartDate,
        periodEndDate, result;

      dueDateString = new DueDateCalculator(assignment).dueDate();
      assignmentDueDate = new Date(dueDateString);
      periodStartDate = new Date(period.start_date);
      periodEndDate = new Date(period.end_date);

      result = (assignmentDueDate >= periodStartDate && assignmentDueDate <= periodEndDate)
        || ((assignmentDueDate === null || dueDateString === null) && period === this.lastPeriod())
        || period.id === '0';

      return result;
    },

    /*
      "Integer" -> Boolean
      Given the id of a grading period (string format), checks whether the
      grading period is active.
    */
    periodIsActive(periodId) {
      var result;

      result = _.chain(this.gradingPeriods.data)
        .map(period => period.id)
        .contains(periodId)
        .value();

      return result;
    },

    /*
      () -> GradingPeriod
      Returns the last (active) grading period of the course
    */
    lastPeriod() {
      var last;

      last = _.find(this.gradingPeriods.data, gradingPeriod => gradingPeriod.is_last);

      return last;
    },

    /*
      () -> "Integer"
      Determines which grading period should be loaded when gradebook is opened
    */
    gradePeriodOnLoad() {
      var currentPeriodId = userSettings.contextGet('gradebook_current_grading_period');

      if (!(currentPeriodId &&
            (currentPeriodId === '0' || this.periodIsActive(currentPeriodId)))) {
        currentPeriodId = GradebookConstants.current_grading_period_id;
      }

      if (currentPeriodId === null || currentPeriodId === undefined) {
        currentPeriodId = '0';
      }

      return currentPeriodId;
    }
  });

  return GradePeriodsStore;
});
