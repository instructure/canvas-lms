/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'jquery',
  'helpers/fakeENV',
  'compiled/SubmissionDetailsDialog'
], ($, fakeENV, SubmissionDetailsDialog) => {

  QUnit.module('#SubmissionDetailsDialog', {

    setup() {
      fakeENV.setup();
      this.clock = sinon.useFakeTimers();
      this.stub($, 'publish')
      ENV.GRADEBOOK_OPTIONS = {
        has_grading_periods: false
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
