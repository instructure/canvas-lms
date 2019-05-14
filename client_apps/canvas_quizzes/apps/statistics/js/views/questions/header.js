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
  var I18n = require('i18n!quiz_statistics').default;
  var ScreenReaderContent = require('jsx!canvas_quizzes/components/screen_reader_content');

  var QuestionHeader = React.createClass({
    getDefaultProps: function() {
      return {
        position: 1,
        responseCount: 0,
        participantCount: 0
      };
    },

    render: function() {
      return (
        <header>
          <ScreenReaderContent tagName="h3">
            {I18n.t('question_header', 'Question %{position}', { position: this.props.position })}
          </ScreenReaderContent>

          {/*
            we'd like SR to read the question description after its position
          */}
          <ScreenReaderContent
            dangerouslySetInnerHTML={{ __html: this.props.questionText }}
            />

          <span className="question-attempts">
            {I18n.t('attempts', 'Attempts: %{count} out of %{total}', {
              count: this.props.responseCount,
              total: this.props.participantCount
            })}
          </span>
        </header>
      );
    }
  });

  return QuestionHeader;
});
