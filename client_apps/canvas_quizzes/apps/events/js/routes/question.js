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
  var React = require('old_version_of_react_used_by_canvas_quizzes_client_apps')
  var WithSidebar = require('jsx!../mixins/with_sidebar')
  var QuestionInspector = require('jsx!../views/question_inspector')
  var QuestionListing = require('jsx!../views/question_listing')

  var QuestionRoute = React.createClass({
    mixins: [WithSidebar],

    getDefaultProps: function() {
      return {
        questions: []
      }
    },

    renderContent: function() {
      var questionId = this.props.params.id
      var question = this.props.questions.filter(function(question) {
        return question.id === questionId
      })[0]

      return (
        <QuestionInspector
          loading={this.props.isLoading}
          question={question}
          currentEventId={this.props.query.event}
          inspectedQuestionId={questionId}
          events={this.props.events}
        />
      )
    },

    renderSidebar: function() {
      return (
        <QuestionListing
          activeQuestionId={this.props.params.id}
          activeEventId={this.props.query.event}
          questions={this.props.questions}
          query={this.props.query}
        />
      )
    }
  })

  return QuestionRoute
})
