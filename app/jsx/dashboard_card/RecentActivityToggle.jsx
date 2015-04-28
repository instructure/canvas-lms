/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'i18n!dashboard',
  'jquery.ajaxJSON'
], function($, React, I18n) {
  var RecentActivityToggle = React.createClass({
    displayName: 'RecentActivityToggle',
    url: '/users/toggle_recent_activity_dashboard',

    getInitialState: function() {
      return {
        recent_activity_dashboard: this.props.recent_activity_dashboard
      };
    },

    handleChange: function(e) {
      this.setState({
        recent_activity_dashboard: $(e.target).prop('checked')
      });
    },

    componentDidUpdate: function() {
      $.ajaxJSON(this.url, 'POST', {}, function() {
        window.location = '/'
      });
    },

    render: function() {
      return (
        <div className="ic-Toggle ic-Toggle--dashcard">
          <input id="ic-Toggle-Dashcard" type="checkbox"
            checked={this.state.recent_activity_dashboard}
            onChange={this.handleChange} />
          <label htmlFor="ic-Toggle-Dashcard">
            <span className="screenreader-only">
              {I18n.t("Toggle dashcard view or recent activity stream")}
            </span>
            <div
              role="presentation"
              className="ic-Toggle__switch"
              data-checked="On"
              data-unchecked="Off">
            </div>
          </label>
        </div>
      )
    }
  });

  return RecentActivityToggle;
});
