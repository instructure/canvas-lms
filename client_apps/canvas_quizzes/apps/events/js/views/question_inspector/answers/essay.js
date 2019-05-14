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
  var K = require('../../../constants');
  var Button = require('jsx!../../../components/button');
  var I18n = require('i18n!quiz_log_auditing.question_answers.essay').default;

  var Essay = React.createClass({
    statics: {
      questionTypes: [ K.Q_ESSAY ]
    },

    getDefaultProps: function() {
      return {
        answer: ''
      };
    },

    getInitialState: function() {
      return {
        htmlView: false
      };
    },

    render: function() {
      var content;

      if (this.state.htmlView) {
        content = (
          <div dangerouslySetInnerHTML={{__html: this.props.answer }} />
        );
      }
      else {
        content = <pre>{this.props.answer}</pre>;
      }

      return (
        <div>
          {content}

          <Button type="default" onClick={this.toggleView}>
            {this.state.htmlView ?
              I18n.t('view_plain_answer', 'View Plain') :
              I18n.t('view_html_answer', 'View HTML')
            }
          </Button>
        </div>
      );
    },

    toggleView: function() {
      this.setState({ htmlView: !this.state.htmlView });
    }
  });

  return Essay;
});