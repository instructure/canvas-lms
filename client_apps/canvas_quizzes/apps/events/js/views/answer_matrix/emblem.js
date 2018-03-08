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

  /**
   * @class Events.Views.AnswerMatrix.Emblem
   *
   * Woop.
   *
   * @seed An emblem for an empty answer.
   *  {}
   *
   * @seed An emblem for some answer.
   *  { "answered": true }
   *
   * @seed An emblem for the final answer.
   *  { "answered": true, "last": true }
   */
  var Emblem = React.createClass({
    getDefaultProps: function() {
      return {}
    },

    shouldComponentUpdate: function(nextProps, nextState) {
      return false
    },

    render: function() {
      var record = this.props
      var className = 'ic-AnswerMatrix__Emblem'

      if (record.answered && record.last) {
        className += ' is-answered is-last'
      } else if (record.answered) {
        className += ' is-answered'
      } else {
        className += ' is-empty'
      }

      return <i className={className} />
    }
  })

  return Emblem
})
