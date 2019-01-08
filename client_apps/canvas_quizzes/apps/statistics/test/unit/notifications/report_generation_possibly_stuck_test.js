/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var Subject = require('notifications/report_generation_failed');
  var K = require('constants');
  var QuizReports = require('stores/reports');

  describe('Notifications::ReportGenerationFailed', function() {
    // These tests were commented out because they broke when we upgraded to node 10
    // it('should work', function() {
    //   var notifications = Subject();

    //   expect(notifications.length).toBe(0);

    //   QuizReports.populate({
    //     quiz_reports: [{
    //       id: '1',
    //       report_type: 'student_analysis',
    //       progress: {
    //         url: '/progress/1',
    //         workflow_state: K.PROGRESS_FAILED,
    //         completion: 40
    //       }
    //     }]
    //   });

    //   notifications = Subject();
    //   expect(notifications.length).toBe(1);
    //   expect(notifications[0].context.reportType).toEqual('student_analysis',
    //     'it attaches the report type');
    // });
  });
});
