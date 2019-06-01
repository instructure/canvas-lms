/** @jsx React.DOM */
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
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps');
  var Text = require('jsx!canvas_quizzes/components/text');
  var K = require('../../constants');
  var I18n = require('i18n!quiz_reports').default;
  var Actions = require('../../actions');
  var Descriptor = require('../../models/quiz_report_descriptor');
  var Alert = require('jsx!canvas_quizzes/components/alert');

  var Notification = React.createClass({
    statics: {
      code: K.NOTIFICATION_REPORT_GENERATION_FAILED
    },

    getDefaultProps: function() {
      return {
      };
    },

    render: function() {
      var readableReportType = Descriptor.getLabel(this.props.reportType);
      var report_type;

      return(
        <Alert autoFocus type="danger" onClick={this.retryOrCancel}>
          <Text
            phrase="notifications.report_generation_failed"
            reportType={readableReportType}>
            It looks like something went wrong while generating the {"%{report_type}"} report.

            You may want to <a href='#' data-action="retry">retry</a> the operation,
            or <a href='#' data-action="abort">cancel</a> it completely.
          </Text>
        </Alert>
      );
    },

    retryOrCancel: function(e) {
      if (e.target.nodeName === 'A') {
        switch (e.target.dataset.action) {
          case 'retry':
            Actions.regenerateReport(this.props.reportId);
          break;

          case 'abort':
            Actions.abortReportGeneration(this.props.reportId);
          break;
        }
      }
    }
  });

  return Notification;
});
