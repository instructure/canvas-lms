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
  var AnswerMatrix = require('jsx!../views/answer_matrix')
  var Config = require('../config')

  var AnswerMatrixRoute = React.createClass({
    statics: {
      willTransitionTo: function(transition, params) {
        if (!Config.allowMatrixView) {
          transition.abort()
        }
      }
    },

    render: function() {
      return (
        <AnswerMatrix
          loading={this.props.isLoading}
          questions={this.props.questions}
          events={this.props.events}
          submission={this.props.submission}
        />
      )
    }
  })

  return AnswerMatrixRoute
})
