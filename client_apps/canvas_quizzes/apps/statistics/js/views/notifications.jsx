/** @jsx React.DOM */
define(function(require) {
  var React = require('react');
  var Actions = require('../actions');
  var I18n = require('i18n!quizzes');
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