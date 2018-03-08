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
  var EventStream = require('jsx!../views/event_stream')
  var Session = require('jsx!../views/session')

  var EventStreamRoute = React.createClass({
    mixins: [],

    getDefaultProps: function() {
      return {}
    },

    render: function() {
      var props = this.props

      return (
        <div>
          <Session
            submission={this.props.submission}
            attempt={this.props.attempt}
            availableAttempts={this.props.availableAttempts}
          />

          <EventStream
            submission={this.props.submission}
            events={this.props.events}
            questions={this.props.questions}
            attempt={this.props.attempt}
          />
        </div>
      )
    }
  })

  return EventStreamRoute
})
