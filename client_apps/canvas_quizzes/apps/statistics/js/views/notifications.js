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
  var Actions = require('../actions');
  var I18n = require('i18n!quizzes').default;
  var NotificationRenderers = [];

  var Notifications = React.createClass({
    getDefaultProps: function() {
      return {
        notifications: []
      };
    },

    render: function() {
      return(
        <ul aria-relevant="additions" aria-live="assertive" id="notifications">
          {this.props.notifications.map(this.renderNotification)}
        </ul>
      );
    },

    renderNotification: function(notification) {
      var renderer = NotificationRenderers.filter(function(type) {
        return type.code === notification.code;
      })[0];

      return (
        <li key={notification.id}>
          <div className="notification">
            {renderer ? renderer(notification.context) : notification.code}
          </div>

          <a
            className="dismiss-notification"
            href="#"
            onClick={this.dismiss.bind(null, notification.id)}>
            {I18n.t('dismiss_notification', 'Dismiss')}
          </a>
        </li>
      );
    },

    dismiss: function(id, e) {
      e.preventDefault();

      Actions.dismissNotification(id);
    }
  });

  return Notifications;
});
