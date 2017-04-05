import INST from 'INST'
import $ from 'jquery'
import 'jquery.instructure_misc_helpers'

  class DownloadSubmissionsDialogManager {
    constructor (assignment, downloadUrlTemplate, submissionsDownloading) {
      this.assignment = assignment;
      this.downloadUrl = $.replaceTags(downloadUrlTemplate, 'assignment_id', assignment.id);
      this.showDialog = this.showDialog.bind(this);
      this.validSubmissionTypes = ['online_upload', 'online_text_entry', 'online_url'];
      this.submissionsDownloading = submissionsDownloading;
    }

    isDialogEnabled () {
      return this.assignment.submission_types && this.assignment.submission_types.some(
        t => this.validSubmissionTypes.includes(t)
      ) && this.assignment.has_submitted_submissions;
    }

    showDialog () {
      this.submissionsDownloading(this.assignment.id);
      INST.downloadSubmissions(this.downloadUrl);
    }
  }

export default DownloadSubmissionsDialogManager
