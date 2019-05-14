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
  var ReactRouter = require('old_version_of_react-router_used_by_canvas_quizzes_client_apps');
  var I18n = require('i18n!quiz_log_auditing.navigation').default;
  var Link = ReactRouter.Link;

  var QuestionListing = React.createClass({
    getDefaultProps: function() {
      return {
        questions: [],
        activeQuestionId: undefined,
        activeEventId: undefined
      };
    },

    render: function() {
      return(
        <div>
          <h2>{I18n.t('questions', 'Questions')}</h2>

          <ol id="ic-QuizInspector__QuestionListing">
            {
              this.props.questions.sort(function(a,b) {
                return a.position > b.position;
              }).map(this.renderQuestion)
            }
          </ol>

          <Link className="no-hover icon-arrow-left" to="app" query={this.props.query}>
            {I18n.t('links.back_to_session_information', 'Back to Log')}
          </Link>
        </div>
      );
    },

    renderQuestion: function(question) {
      return (
        <li key={"question-"+question.id}>
          <Link
            className={this.props.activeQuestionId === question.id ? 'active' : undefined}
            to='/questions/'
            params={{id: question.id}}
            query={this.props.query}>
            {I18n.t('links.question', 'Question %{position}', {
              position: question.position
            })}
          </Link>
        </li>
      );
    }
  });

  return QuestionListing;
});