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
  var classSet = require('canvas_quizzes/util/class_set')

  /**
   * @class Events.Components.Button
   *
   * A wrapper for `<button type="button" />` that abstracts the bootstrap CSS
   * classes we need to specify for buttons.
   */
  var Button = React.createClass({
    getDefaultProps: function() {
      return {
        type: 'default'
      }
    },

    render: function() {
      var className = {}
      var type = this.props.type

      className['btn'] = true
      className['btn-default'] = type === 'default'
      className['btn-danger'] = type === 'danger'
      className['btn-success'] = type === 'success'

      return (
        <button
          onClick={this.props.onClick}
          type="button"
          className={classSet(className)}
          children={this.props.children}
        />
      )
    }
  })

  return Button
})
