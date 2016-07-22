define([
  'jquery',
  'helpers/fakeENV',
  'compiled/SubmissionDetailsDialog'
], ($, fakeENV, SubmissionDetailsDialog) => {

  module('#SubmissionDetailsDialog', {

    setup() {
      fakeENV.setup();
      this.clock = sinon.useFakeTimers();
      this.stub($, 'publish')
      ENV.GRADEBOOK_OPTIONS = {
        multiple_grading_periods_enabled: false
      };
      const assignment = {
        id: 1,
        grading_type: 'points',
        points_possible: 10
      };
      const student = {
        assignment_1: {
          submission_history: []
        }
      };
      const options = {
        change_grade_url: ''
      };
      this.stub($, 'ajaxJSON');
      this.submissionsDetailsDialog = new SubmissionDetailsDialog(assignment, student, options);
    },

    teardown() {
      this.clock.restore();
      fakeENV.teardown();
    }
  });

  test('flashWarning is called when score is 150% points possible', function() {
    const flashWarningStub = this.stub($, 'flashWarning');
    $('.submission_details_grade_form', this.submissionsDetailsDialog.dialog).trigger('submit');
    const callback = $.ajaxJSON.getCall(1).args[3];
    callback({ score: 15, excused: false });
    this.clock.tick(510);
    ok(flashWarningStub.calledOnce);
  });
});
