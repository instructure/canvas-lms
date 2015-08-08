/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'i18n!dashboard',
  'jsx/shared/SVGWrapper',
  'jquery.ajaxJSON'
], function($, React, I18n, SVGWrapper) {
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
        <label className="ic-Super-toggle--ui-switch" htmlFor="ic-Toggle-Dashcard">
          <span className="screenreader-only">
            {I18n.t("Toggle dashcard view or recent activity stream")}
          </span>
          <input type="checkbox" id="ic-Toggle-Dashcard" className="ic-Super-toggle__input"
            checked={this.state.recent_activity_dashboard}
            onChange={this.handleChange} />
          <div className="ic-Super-toggle__container" data-aria-hidden="true" data-checked="On" data-unchecked="Off">
            <div className="ic-Super-toggle__option--LEFT">
              <SVGWrapper url="/images/svg-icons/svg_icon_dashboard2.svg"/>
            </div>
            <div className="ic-Super-toggle__switch"></div>
            <div className="ic-Super-toggle__option--RIGHT">
              <SVGWrapper url="/images/svg-icons/svg_icon_activity_stream.svg"/>
            </div>
          </div>
        </label>
      )
    }
  });

  return RecentActivityToggle;
});
