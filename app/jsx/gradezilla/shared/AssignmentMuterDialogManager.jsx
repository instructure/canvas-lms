define([
  'compiled/AssignmentMuter'
], (AssignmentMuter) => {
  class AssignmentMuterDialogManager {
    constructor (assignment, url, submissionsLoaded) {
      this.assignment = assignment;
      this.url = url;
      this.submissionsLoaded = submissionsLoaded;
      this.showDialog = this.showDialog.bind(this);
      this.isDialogEnabled = this.isDialogEnabled.bind(this);
    }

    showDialog () {
      const assignmentMuter = new AssignmentMuter(
        null, this.assignment, this.url, null, { openDialogInstantly: true }
      );
      assignmentMuter.show();
    }

    isDialogEnabled () {
      return this.submissionsLoaded;
    }
  }

  return AssignmentMuterDialogManager;
});
