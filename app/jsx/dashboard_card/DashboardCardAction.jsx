/** @jsx React.DOM */

define([
  'jquery',
  'react',
  'underscore',
  'i18n!dashcards',
  'bower/classnames/index'
], function($, React, _, I18n, classnames) {
  var DashboardCardAction = React.createClass({
    displayName: 'DashboardCardAction',

    propTypes: {
      hasActivity: React.PropTypes.bool,
      iconClass: React.PropTypes.string,
      path: React.PropTypes.string,
      screenreader: React.PropTypes.string
    },

    getDefaultProps: function () {
      return {
        hasActivity: false
      };
    },

    screenreaderTag: function() {
      var screenreaderText = {};
      if (_.isUndefined(this.props.screenreader)) {
        return "";
      };

      screenreaderText[I18n.t("Unread")] = this.props.hasActivity;
      screenreaderText[this.props.screenreader] = true;
      return (
        <span className="screenreader-only">{classnames(screenreaderText)}</span>
      );
    },

    render: function () {
      var classes = classnames({
        'ic-DashboardCard__action': true,
        'ic-DashboardCard__action--active': this.props.hasActivity
      });
      return (
        <a href={this.props.path} className={classes}>
          <i className={this.props.iconClass} />
          {this.screenreaderTag()}
        </a>
      );
    }
  });

  return DashboardCardAction;
});
