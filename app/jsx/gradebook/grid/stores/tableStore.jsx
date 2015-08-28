define([
  'bower/reflux/dist/reflux',
  'underscore',
  'jsx/gradebook/grid/constants',
  'jsx/gradebook/grid/stores/studentEnrollmentsStore',
  'jsx/gradebook/grid/stores/gradebookToolbarStore',
  'jsx/gradebook/grid/stores/assignmentGroupsStore',
  'jsx/gradebook/grid/stores/gradingPeriodsStore',
  'jsx/gradebook/grid/stores/submissionsStore',
  'jsx/gradebook/grid/stores/customColumnsStore'
], function (Reflux, _, GradebookConstants, StudentEnrollmentsStore, GradebookToolbarStore,
             AssignmentGroupsStore, GradingPeriodsStore, SubmissionsStore,
             CustomColumnsStore) {
  var tableStore = Reflux.createStore({
    init() {
      this.state = {
        students: null,
        allAssignments: null,
        assignments: null,
        submissions: null,
        toolbarOptions: GradebookToolbarStore.toolbarOptions,
        gradingPeriods: null,
        assignmentGroups: null,
        error: null,
        rows: null,
        customColumns: null
      };
      this.listenTo(GradebookToolbarStore, this.onToolbarOptionsChanged);
      this.listenTo(StudentEnrollmentsStore, this.onEnrollmentsChanged);
      this.listenTo(AssignmentGroupsStore, this.onAssignmentGroupsChanged);
      this.listenTo(SubmissionsStore, this.onSubmissionsChanged);
      this.listenTo(GradingPeriodsStore, this.onGradingPeriodsChanged);
      this.listenTo(CustomColumnsStore, this.onCustomColumnsChanged);
    },

    getInitialState() {
      return this.state;
    },

    onEnrollmentsChanged(enrollmentData) {
      this.state.students = enrollmentData.data;
      this.constructTableData();
      this.trigger(this.state);
    },

    onAssignmentGroupsChanged(assignmentGroupData) {
      var arrangeBy, assignments;

      arrangeBy = this.state.toolbarOptions.arrangeColumnsBy;
      assignments = _.chain(assignmentGroupData.data)
        .map(assignmentGroup => assignmentGroup.assignments)
        .flatten()
        .reject(assignment => _.contains(assignment.submission_types, 'attendence'))
        .filter(assignment => assignment.published)
        .value();

      this.state.allAssignments = _.groupBy(assignments, assignment => assignment.id);
      this.state.assignments = this.state.allAssignments
      this.state.assignmentGroups = _.map(assignmentGroupData.data, group => {
        group.columnId = 'assignment_group_' + group.id;
        return group;
      });
      this.constructTableData();
      this.filterAssignmentsByPeriod();
      this.trigger(this.state);
    },

    filterAssignmentsByPeriod() {
      var assignments;

      if (this.state.allAssignments === null || this.state.gradingPeriods === null) {
          return;
      }

      assignments = _.flatten(_.values(this.state.allAssignments));
      assignments = _.filter(assignments, assignment =>
                GradingPeriodsStore.assignmentIsInPeriod(assignment, GradingPeriodsStore.selected()));

      this.state.assignments = assignments;
      this.trigger(this.state)
    },

    onSubmissionsChanged(submissionsData) {
      var submissions;
      submissions = _.groupBy(submissionsData.data, submission => submission.user_id);
      this.state.submissions = submissions;
      this.constructTableData();
      this.trigger(this.state);
    },

    onToolbarOptionsChanged(toolbarOptionsData) {
      this.state.toolbarOptions = toolbarOptionsData;
      this.trigger(this.state);
    },

    onGradingPeriodsChanged(gradingPeriodsData) {
      this.state.gradingPeriods = gradingPeriodsData
      this.filterAssignmentsByPeriod();
      this.trigger(this.state);
    },

    onCustomColumnsChanged(customColumnsData) {
      if (customColumnsData.error) {
        this.state.error = customColumnsData.error;
      }

      this.state.customColumns = customColumnsData;
      this.constructTableData();
      this.trigger(this.state);
    },

    constructTableData() {
      var students, assignments, submissions, assignmentGroups, customColumns;

      students = this.state.students;
      assignments = this.state.assignments;
      submissions = this.state.submissions;
      assignmentGroups = this.state.assignmentGroups;
      customColumns = this.state.customColumns;

      if (students && assignments && submissions && customColumns) {
        this.state.rows = _.map(students, student => {
          var displayName, rowData, userSubmissions, teacherNote;

          displayName = GradebookConstants.list_students_by_sortable_name_enabled ?
            student.user.sortable_name : student.user.name;

          userSubmissions = _.flatten(_.map(submissions[student.user_id], s => s.submissions));
          userSubmissions = _.groupBy(userSubmissions, s => s.assignment_id);
          teacherNote = _.find(
            customColumns.teacherNotes,
            note => note.user_id === student.user_id
          );

          rowData = {
            studentName: displayName,
            submissions: userSubmissions,
            assignmentGroups: assignmentGroups,
            student: student,
            teacherNote: teacherNote ? teacherNote.content : ''
          }

          return rowData;
        });
      }
    }

  });

  return tableStore;
});
