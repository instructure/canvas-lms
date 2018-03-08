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
  var NO_ANSWER = require('jsx!./no_answer')
  var keys = Object.keys

  var FIMB = React.createClass({
    statics: {
      questionTypes: [K.Q_FILL_IN_MULTIPLE_BLANKS]
    },

    render: function() {
      var answer = this.props.answer

      return (
        <table>
          {keys(answer).map(function(blank) {
            return (
              <tr key={'blank' + blank}>
                <th scope="row">{blank}</th>
                <td>{answer[blank] || NO_ANSWER}</td>
              </tr>
            )
          })}
        </table>
      )
    }
  })

  return FIMB
})
