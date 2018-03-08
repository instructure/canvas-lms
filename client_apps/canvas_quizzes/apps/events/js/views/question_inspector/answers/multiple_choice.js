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
  var K = require('../../../constants')

  var MultipleChoice = React.createClass({
    statics: {
      questionTypes: [K.Q_MULTIPLE_CHOICE, K.Q_TRUE_FALSE]
    },

    getDefaultProps: function() {
      return {
        answer: [],
        question: {answers: []}
      }
    },

    render: function() {
      return (
        <div className="ic-QuestionInspector__MultipleChoice">
          {this.props.question.answers.map(this.renderAnswer)}
        </div>
      )
    },

    renderAnswer: function(answer) {
      var isSelected = this.props.answer.indexOf('' + answer.id) > -1

      return (
        <div key={'answer' + answer.id}>
          <input type="radio" readOnly disabled={!isSelected} checked={isSelected} />

          {answer.text}
        </div>
      )
    }
  })

  return MultipleChoice
})
