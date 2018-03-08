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
  var classSet = require('../util/class_set')
  var $ = require('jquery')

  // TODO: use $.fn.is(':in_viewport') when it becomes available
  var isInViewport = function(el) {
    var $el = $(el)
    var $window = $(window)

    var vpTop = $window.scrollTop()
    var vpBottom = vpTop + $window.height()
    var elTop = $el.offset().top
    var elBottom = elTop + $el.height()

    return vpTop < elTop && vpBottom > elBottom
  }

  /**
   * @class Components.Alert
   *
   * A Bootstrap alert-like component.
   */
  var Alert = React.createClass({
    propTypes: {
      /**
       * @cfg {Boolean} [autoFocus=false]
       *
       * If true, the alert will auto-focus itself IF it is visible within
       * the viewport (e.g, the user can currently see it.).
       *
       * This is useful to force ScreenReaders to read the notification.
       */
      autoFocus: React.PropTypes.bool
    },

    getDefaultProps: function() {
      return {
        type: 'danger',
        autoFocus: false
      }
    },

    componentDidMount: function() {
      if (this.props.autoFocus) {
        var myself = this.getDOMNode()

        if (isInViewport(myself)) {
          setTimeout(function() {
            myself.focus()
          }, 1)
        }
      }
    },

    render: function() {
      var className = {}

      className['alert'] = true
      className['alert-' + this.props.type] = true

      return (
        <div
          tabIndex="-1"
          aria-role="alert"
          aria-live="assertive"
          aria-relevant="all"
          onClick={this.props.onClick}
          className={classSet(className)}
          children={this.props.children}
        />
      )
    }
  })

  return Alert
})
