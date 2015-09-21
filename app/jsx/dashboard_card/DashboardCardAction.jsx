/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'i18n!dashcards',
  'bower/classnames/index'
], function($, React, I18n) {
  var DashboardCardAction = React.createClass({
    displayName: 'DashboardCardAction',

    propTypes: {
      unreadCount: React.PropTypes.number,
      iconClass: React.PropTypes.string,
      path: React.PropTypes.string,
      actionType: React.PropTypes.string
    },

    getDefaultProps: function() {
      return {
        unreadCount: 0
      }
    },

    unreadCountLimiter: function() {
      var count = this.props.unreadCount
      count = (count < 100) ? count : '99+'
      return (
        <span className="unread_count">{count}</span>
      )
    },

    render: function () {
      return (
        <a href={this.props.path} className="ic-DashboardCard__action">
          { this.props.actionType ? (
            <span className="screenreader-only">{
              this.props.actionType
            }</span>
            ) : null
          }

          <div className="ic-DashboardCard__action-layout">
            <i className={this.props.iconClass} />
            {
              (this.props.unreadCount > 0) ? (
                <span className="ic-DashboardCard__action-badge">
                  { this.unreadCountLimiter() }
                  <span className="screenreader-only">{
                    I18n.t("Unread")
                  }</span>
                </span>
              ) : null
            }
          </div>
        </a>
      );
    }
  });

  return DashboardCardAction;
});
