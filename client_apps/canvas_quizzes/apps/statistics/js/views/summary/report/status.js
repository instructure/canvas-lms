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
  var I18n = require('i18n!quiz_reports').default;
  var K = require('../../../constants');
  var Descriptor = require('../../../models/quiz_report_descriptor');
  var Actions = require('../../../actions');

  var Status = React.createClass({
    propTypes: {
      generatable: React.PropTypes.bool,
      isGenerated: React.PropTypes.bool,

      file: React.PropTypes.shape({
        createdAt: React.PropTypes.string,
      }),

      progress: React.PropTypes.shape({
        workflowState: React.PropTypes.string,
        completion: React.PropTypes.number,
      }),
    },

    getInitialState: function() {
      return {
        justBeenGenerated: false
      };
    },

    getDefaultProps: function() {
      return {
        generatable: true,
        file: {},
        progress: {}
      };
    },

    componentWillReceiveProps: function(nextProps) {
      if (this.props.isGenerating && nextProps.isGenerated) {
        this.setState({
          justBeenGenerated: true
        });
      }
    },

    render: function() {
      var label = Descriptor.getDetailedStatusLabel(this.props, this.state.justBeenGenerated);

      return (
        <div className="quiz-report-status">
          {this.props.isGenerating ? this.renderProgress(label) : label}
        </div>
      );
    },

    renderProgress: function(label) {
      var completion = this.props.progress.completion;
      var cancelable = this.props.progress.workflowState === K.PROGRESS_QUEUED;

      return (
        <div className="auxiliary">
          <p>
            <span className="screenreader-only" children={label} />
            <span aria-hidden="true">
              {I18n.t('generating', 'Report is being generated...')}
              {' '}
              {cancelable &&
                <a href="#" onClick={this.cancel}>{I18n.t('cancel_generation', 'Cancel')}</a>
              }
            </span>
          </p>

          <div className="progress">
            <div className="bar" style={{ width: (completion || 0) + '%' }} />
          </div>
        </div>
      );
    },

    cancel: function() {
      Actions.abortReportGeneration(this.props.id);
    }
  });

  return Status;
});
