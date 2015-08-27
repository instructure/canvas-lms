
define([
  'bower/reflux/dist/reflux',
  '../actions/gradebookToolbarActions',
  'jquery',
  'underscore',
  'i18n!gradebook2',
  'compiled/userSettings',
  '../constants'
], function (Reflux, GradebookToolbarActions, $, _, I18n, userSettings, GradebookConstants) {
  // GradebooToolbarStoreSingleton will only get set to null the first time require.js executes this.
  // On subsequent calls, require.js will remember the return value and won't reset this to null.
  var GradebookToolbarStoreSingleton = null;
  var createGradebookToolbarStore = () => {
    var GradebookToolbarStore = Reflux.createStore({
      listenables: [GradebookToolbarActions],

      getInitialState() {
        if (this.toolbarOptions) {
          return this.toolbarOptions;
        }
        var storedSortOrder = GradebookConstants.gradebook_column_order_settings ||
          { sortType: 'assignment_group' };

        var savedOptions = {
          hideStudentNames: userSettings.contextGet('hideStudentNames'),
          hideNotesColumn: !GradebookConstants.teacher_notes || GradebookConstants.teacher_notes.hidden,
          arrangeColumnsBy: storedSortOrder.sortType,
          treatUngradedAsZero: userSettings.contextGet('treatUngradedAsZero'),
          showAttendanceColumns: userSettings.contextGet('showAttendanceColumns'),
          totalColumnInFront: userSettings.contextGet('total_column_in_front'),
          warnedAboutTotalsDisplay: userSettings.contextGet('warned_about_totals_display'),
          showTotalGradeAsPoints: GradebookConstants.show_total_grade_as_points
        };

        this.toolbarOptions = _.defaults(savedOptions, GradebookConstants.DEFAULT_TOOLBAR_PREFERENCES);
        return this.toolbarOptions;
      },

      onToggleStudentNames(hideStudentNames) {
        this.toolbarOptions.hideStudentNames = hideStudentNames;
        this.trigger(this.toolbarOptions);
      },

      onToggleNotesColumnCompleted(hideNotesColumn) {
        this.toolbarOptions.hideNotesColumn = hideNotesColumn;
        this.trigger(this.toolbarOptions);
      },

      onArrangeColumnsBy(criteria) {
        this.toolbarOptions.arrangeColumnsBy = criteria;
        this.trigger(this.toolbarOptions);
      },

      onToggleTreatUngradedAsZero(treatUngradedAsZero) {
        this.toolbarOptions.treatUngradedAsZero = treatUngradedAsZero;
        this.trigger(this.toolbarOptions);
      },

      onToggleShowAttendanceColumns(showAttendanceColumns) {
        this.toolbarOptions.showAttendanceColumns = showAttendanceColumns;
        this.trigger(this.toolbarOptions);
      },

      onToggleTotalColumnInFront(totalColumnInFront) {
        this.toolbarOptions.totalColumnInFront = totalColumnInFront;
        this.trigger(this.toolbarOptions);
      },

      onShowTotalGradeAsPoints(showAsPoints) {
        this.toolbarOptions.showTotalGradeAsPoints = showAsPoints;
        this.trigger(this.toolbarOptions);
      },

      onHideTotalDisplayWarning(hideWarning) {
        this.toolbarOptions.warnedAboutTotalsDisplay = hideWarning;
        this.trigger(this.toolbarOptions);
      }

    });

    return GradebookToolbarStore;
  };

  var getGradebookToolbarStore = () => {
    if (GradebookToolbarStoreSingleton === null) {
      GradebookToolbarStoreSingleton = createGradebookToolbarStore();
    }
    return GradebookToolbarStoreSingleton;
  };

  return getGradebookToolbarStore();
});
