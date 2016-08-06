define([
  'react',
  'fixed-data-table',
  'jquery',
  'underscore',
  'bower/reflux/dist/reflux',
  'i18n!gradebook2',
  'jsx/gradebook/grid/wrappers/columnFactory',
  'jsx/gradebook/grid/wrappers/headerWrapper',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/actions/assignmentGroupsActions',
  'jsx/gradebook/grid/stores/settingsStore',
  'jsx/gradebook/grid/actions/settingsActions',
  'jsx/gradebook/grid/stores/gradebookToolbarStore',
  'jsx/gradebook/grid/stores/gradingPeriodsStore',
  'jsx/gradebook/grid/actions/studentEnrollmentsActions',
  'jsx/gradebook/grid/actions/submissionsActions',
  'jsx/gradebook/grid/actions/customColumnsActions',
  'jsx/gradebook/grid/stores/keyboardNavigationStore',
  'jsx/gradebook/grid/actions/keyboardNavigationActions',
  'jsx/gradebook/grid/stores/tableStore',
  'jsx/gradebook/grid/actions/sectionsActions',
  'jsx/gradebook/grid/helpers/columnArranger',
  'vendor/spin',
  'jsx/gradebook/grid/helpers/submissionsHelper'
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
  AssignmentGroupsActions,
  SettingsStore,
  SettingsActions,
  GradebookToolbarStore,
  GradingPeriodsStore,
  StudentEnrollmentsActions,
  SubmissionsActions,
  CustomColumnsActions,
  KeyboardNavigationStore,
  KeyboardNavigationActions,
  TableStore,
  SectionsActions,
  ColumnArranger,
  Spinner,
  SubmissionsHelper
){
  var Table = FixedDataTable.Table,
    Column = FixedDataTable.Column,
    isColumnResizing = false,
    spinner;

  var Gradebook = React.createClass({
    mixins: [
      Reflux.connect(KeyboardNavigationStore, 'keyboardNav'),
      Reflux.connect(SettingsStore, 'settings'),
      Reflux.connect(GradebookToolbarStore, 'toolbarOptions'),
      Reflux.connect(TableStore, 'tableData')
    ],

    componentWillMount() {
      AssignmentGroupsActions.load();
      StudentEnrollmentsActions.load()
        .then((studentEnrollments) => {
          var studentIds = _.pluck(studentEnrollments, 'user_id');
          SubmissionsActions.load(studentIds);
        });
      SectionsActions.load();
      CustomColumnsActions.loadTeacherNotes();
      CustomColumnsActions.load();
    },

    componentDidMount() {
      SettingsActions.resize();
      $(window).resize(SettingsActions.resize);
    },

    componentDidUpdate() {
      KeyboardNavigationActions.constructKeyboardNavManager();
    },

    handleKeyDown(event) {
      var reactGradebook = document.getElementById('react-gradebook-canvas');
      var knownCodes = GradebookConstants.RECOGNIZED_KEYBOARD_CODES;
      if (_.contains(knownCodes, event.keyCode)) {
        event.nativeEvent.preventDefault();
        event.persist();
        KeyboardNavigationActions.handleKeyboardEvent(event);
        $(reactGradebook).focus();
      }
    },

    assignments() {
      var arrangeBy, comparator, assignments;

      arrangeBy = this.state.toolbarOptions.arrangeColumnsBy;
      comparator = ColumnArranger.getComparator(arrangeBy);
      assignments = _.chain(this.state.tableData.assignments.data)
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
      return this.state.tableData.rows[index];
    },

    isColumnFixed(columnType) {
      return columnType === GradebookConstants.STUDENT_COLUMN_ID
          || columnType === GradebookConstants.SECONDARY_COLUMN_ID
          || columnType === GradebookConstants.TOTAL_COLUMN_ID
             && this.state.toolbarOptions.totalColumnInFront;
    },

    renderColumn(columnName, columnType, columnId, cellDataGetter, assignment, customColumnData) {
      var columnIdentifier = columnId || columnType,
        columnWidth = this.getColumnWidth(columnIdentifier),
        enrollments = this.state.tableData.students,
        submissions = this.state.tableData.submissions,
        columnData = {
          columnType: columnType,
          activeCell: this.state.keyboardNav.currentCellIndex,
          setActiveCell: KeyboardNavigationActions.setActiveCell,
          assignment: assignment,
          enrollments: enrollments,
          submissions: submissions,
          customColumnData: customColumnData
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
      var cellDataGetter;

      cellDataGetter = function(columnId, rowData) {
        var assignmentGroups, assignmentGroup, submissions;

        assignmentGroups = this.state.tableData.assignmentGroups;
        assignmentGroup = _.find(assignmentGroups, group => group.columnId === columnId);
        submissions = rowData.submissions;

        return {
          assignmentGroup: assignmentGroup,
          submissions: submissions,
          columnId: columnId
        };
      }.bind(this);
      return _.map(assignmentGroups, (assignmentGroup, index) => {
        var columnId = assignmentGroup.columnId;


        return this.renderColumn(assignmentGroup.name,
                                 GradebookConstants.ASSIGNMENT_GROUP_COLUMN_ID,
                                 columnId, cellDataGetter);
      });
    },

    renderAssignmentColumns(assignments) {
      var cellDataGetter;
      cellDataGetter = function(columnId, rowData) {
        var submissions, submission;

        submissions = rowData.submissions[columnId];
        if (submissions && submissions.length > 0) {
          submission = submissions[0];
        }

        return submission;
      }.bind(this);

      return _.map(assignments, (assignment) => {
        var columnId = assignment.id;

        return this.renderColumn(assignment.name, assignment.grading_type, columnId, cellDataGetter, assignment);
      });
    },

    hasStoreErrorOccured() {
      return this.state.tableData.error;
    },

    renderSpinner() {
      spinner = new Spinner();
      $(spinner.spin().el).css({
        opacity: 0.5,
        top: '55px',
        left: '50%'
      }).addClass('use-css-transitions-for-show-hide').appendTo('#main');
    },

    removeSpinner() {
      if (spinner) {
        $(spinner.el).remove();
        spinner = null;
      }
    },

    renderNotesColumn() {
      if (!this.state.toolbarOptions.hideNotesColumn) {
        return this.renderColumn(I18n.t('Notes'), GradebookConstants.NOTES_COLUMN_ID, 'notesColumn');
      }
    },

    renderCustomColumns(customColumns) {
      let customColumnData, mapFunction;

      customColumnData = customColumns.customColumns.data;
      mapFunction = function(customColumn) {
        var columnId, columnData;

        columnId = 'customColumn_' + customColumn.id;
        columnData = this.state.tableData.customColumns.customColumns.columnData;
        return this.renderColumn(customColumn.title, GradebookConstants.CUSTOM_COLUMN_ID, columnId, (columnId, rowData) => columnData[customColumn.id][rowData.student.user_id], null, customColumn);
      };

      return _.map(customColumnData, mapFunction.bind(this));
    },

    renderAllColumns() {
      var arrangeBy, columns, comparator, showTotalInFront, total;

      arrangeBy = this.state.toolbarOptions.arrangeColumnsBy;
      comparator = ColumnArranger.getComparator(arrangeBy);
      total = this.renderColumn(I18n.t('Total'), 'total');
      showTotalInFront = this.state.toolbarOptions.totalColumnInFront,
      columns = [
        this.renderColumn(I18n.t('Student Name'), GradebookConstants.STUDENT_COLUMN_ID),
        this.renderNotesColumn(),
        this.renderCustomColumns(this.state.tableData.customColumns),
        this.renderAssignmentColumns(_.flatten(_.values(this.state.tableData.assignments)).sort(comparator), this.state.tableData.submissions),
        this.renderAssignmentGroupColumns(this.state.tableData.assignmentGroups),
      ];

      (showTotalInFront) ? columns.splice(1, 0, total) : columns.push(total);

      return columns;
    },

    render() {
      if (this.hasStoreErrorOccured()) {
        $.flashError(I18n.t('There was a problem loading the gradebook.'));
      }
      else if (!this.state.tableData.loading) {
        this.removeSpinner();
        return (
          <div id="react-gradebook-canvas"
               onKeyDown={this.handleKeyDown}
               tabIndex="0">
            <Table
              rowGetter={this.rowGetter}
              rowsCount={this.state.tableData.students.length}
              scrollToColumn={this.state.keyboardNav.currentColumnIndex}
              scrollToRow={this.state.keyboardNav.currentRowIndex}
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
