/** @jsx React.DOM */
define([
  'react',
  'fixed-data-table',
  'jquery',
  'underscore',
  'bower/reflux/dist/reflux',
  'i18n!gradebook2',
  '../wrappers/columnFactory',
  '../wrappers/headerWrapper',
  '../constants',
  '../stores/assignmentGroupsStore',
  '../actions/assignmentGroupsActions',
  '../stores/settingsStore',
  '../actions/settingsActions',
  '../stores/gradebookToolbarStore',
  '../stores/studentEnrollmentsStore',
  '../stores/gradingPeriodsStore',
  '../actions/studentEnrollmentsActions',
  '../stores/submissionsStore',
  '../actions/submissionsActions',
  '../stores/keyboardNavigationStore',
  '../actions/keyboardNavigationActions',
  '../helpers/columnArranger',
  'vendor/spin'
], function (
  React,
  FixedDataTable,
  $,
  _,
  Reflux,
  I18n,
  ColumnFactory,
  HeaderWrapper,
  GradebookConstants,
  AssignmentGroupsStore,
  AssignmentGroupsActions,
  SettingsStore,
  SettingsActions,
  GradebookToolbarStore,
  StudentEnrollmentsStore,
  GradingPeriodsStore,
  StudentEnrollmentsActions,
  SubmissionsStore,
  SubmissionsActions,
  KeyboardNavigationStore,
  KeyboardNavigationActions,
  ColumnArranger,
  Spinner
){

  var Table = FixedDataTable.Table,
      Column = FixedDataTable.Column,
      isColumnResizing = false,
      spinner;

  var Gradebook = React.createClass({
    mixins: [
      Reflux.connect(KeyboardNavigationStore, 'currentCellIndex'),
      Reflux.connect(AssignmentGroupsStore, 'assignmentGroups'),
      Reflux.connect(SettingsStore, 'settings'),
      Reflux.connect(StudentEnrollmentsStore, 'studentEnrollments'),
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions'),
      Reflux.connect(SubmissionsStore, 'submissions'),
      Reflux.connect(GradingPeriodsStore, 'gradingPeriods')
    ],

    componentWillMount() {
      AssignmentGroupsActions.load();
      StudentEnrollmentsActions.load()
      .then((studentEnrollments) => {
        var studentIds = _.pluck(studentEnrollments, 'user_id');
        SubmissionsActions.load(studentIds);
      });
    },

    componentDidMount() {
      SettingsActions.resize();
      $(window).resize(SettingsActions.resize);
    },

    handleKeyDown(event) {
      var reactGradebook = document.getElementById('react-gradebook-canvas');
      var handled = true;

      if (event.keyCode === 9) {
        if (event.shiftKey) {
          KeyboardNavigationActions.previous();
        } else {
          KeyboardNavigationActions.next();
        }
      } else if (event.keyCode === 13) {
        if (event.shiftKey) {
          KeyboardNavigationActions.up();
        } else {
          KeyboardNavigationActions.down();
        }
      } else if (event.keyCode === 37) {
        KeyboardNavigationActions.previous();
      } else if (event.keyCode === 38) {
        KeyboardNavigationActions.up();
      } else if (event.keyCode === 39) {
        KeyboardNavigationActions.next();
      } else if (event.keyCode === 40) {
        KeyboardNavigationActions.down();
      } else {
        handled = false;
      }

      if (handled) {
        event.nativeEvent.preventDefault();
        $(reactGradebook).focus();
      }
    },

    assignments() {
      var arrangeBy, comparator, assignments;

      arrangeBy = this.state.toolbarOptions.arrangeColumnsBy;
      comparator = ColumnArranger.getComparator(arrangeBy);
      assignments = _.chain(this.state.assignmentGroups.data)
        .map(assignmentGroup => assignmentGroup.assignments)
        .flatten()
        .filter(assignment => assignment.published)
        .filter(assignment =>
                GradingPeriodsStore.assignmentIsInPeriod(assignment, GradingPeriodsStore.selected()))
        .value();
      return assignments.sort(comparator);
    },

    getColumnWidth(column) {
      var customWidths = this.state.settings.columnWidths,
          defaultWidth = GradebookConstants.DEFAULT_LAYOUTS.headers.width,
          width = (customWidths && customWidths[column]) || defaultWidth;

      return parseInt(width);
    },

    handleColumnResize(newColumnWidth, dataKey) {
      SettingsActions.saveColumnSize(newColumnWidth, dataKey);
      isColumnResizing = false;
    },

    rowGetter(index) {
      var enrollmment, submissions;

      enrollment = this.state.studentEnrollments.data[index];
      submissions = _.find(this.state.submissions.data,
        (submission) => submission.user_id === enrollment.user_id)
        .submissions;

      return {
        enrollment: enrollment,
        assignmentGroups: this.state.assignmentGroups.data,
        submissions: submissions
      };
    },

    isColumnFixed(columnType) {
      return columnType === GradebookConstants.STUDENT_COLUMN_ID
          || columnType === GradebookConstants.SECONDARY_COLUMN_ID
          || columnType === GradebookConstants.TOTAL_COLUMN_ID
             && this.state.toolbarOptions.totalColumnInFront;
    },

    renderColumn(columnName, columnType, columnId, cellDataGetter, assignment) {
      var columnIdentifier = columnId || columnType,
          columnWidth = this.getColumnWidth(columnIdentifier),
          enrollments = this.state.studentEnrollments.data,
          columnData = {
            columnType: columnType,
            activeCell: this.state.currentCellIndex,
            setActiveCell: KeyboardNavigationActions.setActiveCell,
            assignment: assignment,
            enrollments: enrollments
          };

      return (
        <Column
          label={columnName}
          fixed={this.isColumnFixed(columnType)}
          cellDataGetter={cellDataGetter}
          width={columnWidth}
          dataKey={columnIdentifier}
          columnData={columnData}
          headerRenderer={HeaderWrapper.getHeader}
          cellRenderer={ColumnFactory.getRenderer}
          isResizable={true}
          minWidth={90}
          key={columnIdentifier}/>
      );
    },

    renderAssignmentGroupColumns(assignmentGroups) {
      return _.map(assignmentGroups, (assignmentGroup, index) => {
        var columnId = 'assignment_group_' + assignmentGroup.id,
          cellDataGetter = () => index;


        return this.renderColumn(assignmentGroup.name,
                                 GradebookConstants.ASSIGNMENT_GROUP_COLUMN_ID,
                                 columnId, cellDataGetter);
      });
    },

    renderAssignmentColumns(assignments) {
      return _.map(assignments, (assignment) => {
        var columnId = 'assignment_' + assignment.id,
            cellDataGetter = () => assignment;

        return this.renderColumn(assignment.name, assignment.grading_type, columnId, cellDataGetter, assignment);
      });
    },

    hasStoreErrorOccured() {
      return this.state.assignmentGroups.error
             || this.state.studentEnrollments.error
             || this.state.submissions.error;
    },

    renderSpinner() {
      spinner = new Spinner();
      $(spinner.spin().el).css({
        opacity: 0.5,
        top: '55px',
        left: '50%'
      }).addClass('use-css-transitions-for-show-hide').appendTo('#main');
    },

    renderNotesColumn() {
      if (!this.state.toolbarOptions.hideNotesColumn) {
        return this.renderColumn(I18n.t('Notes'), GradebookConstants.NOTES_COLUMN_ID);
      }
    },

    renderAllColumns() {
      var total = this.renderColumn(I18n.t('Total'), 'total'),
          showTotalInFront = this.state.toolbarOptions.totalColumnInFront,
          columns = [
            this.renderColumn(I18n.t('Student Name'), GradebookConstants.STUDENT_COLUMN_ID),
            this.renderColumn(I18n.t('Secondary ID'), GradebookConstants.SECONDARY_COLUMN_ID),
            this.renderNotesColumn(),
            this.renderAssignmentColumns(this.assignments(), this.state.submissions),
            this.renderAssignmentGroupColumns(this.state.assignmentGroups.data),
          ];

      (showTotalInFront) ? columns.splice(2, 0, total) : columns.push(total);
      return columns;
    },

    render() {
      if (this.hasStoreErrorOccured()) {
        $.flashError(I18n.t('There was a problem loading the gradebook.'));
      }
      else if (this.state.submissions.data && this.state.assignmentGroups.data
               && this.state.studentEnrollments.data) {

        $(spinner.el).remove();

        return (
          <div id="react-gradebook-canvas"
               onKeyDown={this.handleKeyDown}
               tabIndex="0">
            <Table
              rowGetter={this.rowGetter}
              rowsCount={this.state.studentEnrollments.data.length}
              onColumnResizeEndCallback={this.handleColumnResize}
              isColumnResizing={isColumnResizing}
              rowHeight={GradebookConstants.DEFAULT_LAYOUTS.rows.height}
              height={this.state.settings.height}
              width={this.state.settings.width}
              headerHeight={GradebookConstants.DEFAULT_LAYOUTS.headers.height}>
              {this.renderAllColumns()}
            </Table>
          </div>
        );
      } else {
        if (!spinner) {
          this.renderSpinner();
        }

        return <div/>;
      }
    }
  });

  return Gradebook;
});
