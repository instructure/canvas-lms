define([
  'compiled/AssignmentDetailsDialog'
], (AssignmentDetailsDialog) => {
  function prepareAssignment (assignment) {
    return {
      id: assignment.id,
      name: assignment.name,
      points_possible: assignment.pointsPossible
    };
  }

  function prepareStudents (students, assignmentId) {
    return students.map((student) => {
      const processedStudent = {};

      if (student.submission) {
        processedStudent[`assignment_${assignmentId}`] = {
          score: student.submission.score
        }
      }

      return processedStudent;
    });
  }

  function getAssignmentDetailsDialogOptions (assignment, students) {
    return {
      assignment: prepareAssignment(assignment),
      students: prepareStudents(students, assignment.id)
    };
  }

  class AssignmentDetailsDialogManager {
    constructor (assignment, students, submissionsLoaded = false) {
      this.assignment = assignment;
      this.students = students;
      this.submissionsLoaded = submissionsLoaded;

      this.showDialog = this.showDialog.bind(this);
    }

    showDialog () {
      const opts = getAssignmentDetailsDialogOptions(this.assignment, this.students);
      const dialog = new AssignmentDetailsDialog(opts);

      dialog.show();
    }

    isDialogEnabled () {
      return this.submissionsLoaded;
    }
  }

  return AssignmentDetailsDialogManager;
});
