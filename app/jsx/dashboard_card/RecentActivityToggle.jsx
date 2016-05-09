define([
  'jquery',
  'react',
  'i18n!dashboard',
  'jsx/shared/SVGWrapper',
  'classnames',
  'jquery.ajaxJSON'
], function($, React, I18n, SVGWrapper, classNames) {
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
        recent_activity_dashboard: !this.state.recent_activity_dashboard
      });
    },

    componentDidUpdate: function() {
      $('#dashboard-activity').toggle();
      $('#DashboardCard_Container').toggle();
      $.ajaxJSON(this.url, 'POST');
    },

    render: function() {
      var ToggleButtonClasses = classNames(
        'dashboard-toggle-button',
        {
          'dashboard-toggle-button--toggle-left': !this.state.recent_activity_dashboard,
          'dashboard-toggle-button--toggle-right': this.state.recent_activity_dashboard
        }
      );

      return (
        <div>
          <button
            id="dashboardToggleButton"
            className={ToggleButtonClasses}
            onClick={this.handleChange}>
            <span className="screenreader-only">
              {this.state.recent_activity_dashboard ? I18n.t("Show dashboard card view") : I18n.t("Show recent activity stream")}
            </span>
            <div className="dashboard-toggle-button-layout" aria-hidden={true}>
              <div
                className={
                  (this.state.recent_activity_dashboard ?
                    "dashboard-toggle-button-icon"
                    :
                    "dashboard-toggle-button-icon dashboard-toggle-button-icon--active"
                  )}
                id="dashboardToggleButtonGridIcon"
              >
                <SVGWrapper url="/images/svg-icons/svg_icon_dashboard2.svg"/>
              </div>
              <div className="dashboard-toggle-button-switch"></div>
              <div
                className={
                  (this.state.recent_activity_dashboard ?
                    "dashboard-toggle-button-icon dashboard-toggle-button-icon--active"
                    :
                    "dashboard-toggle-button-icon"
                  )}
                id="dashboardToggleButtonStreamIcon"
              >
                <SVGWrapper url="/images/svg-icons/svg_icon_activity_stream.svg"/>
              </div>
            </div>
          </button>
        </div>
      )
    }
  });
  return RecentActivityToggle;
});
