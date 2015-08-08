/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper',
  'compiled/fn/preventDefault'
], (I18n, React, SVGWrapper, PreventDefault) => {

  var ProfileTray = React.createClass({

    propTypes: {
      closeTray: React.PropTypes.func.isRequired
    },

    render() {
      return (
        <div>
          <div className="ReactTray__header">
            <h1 className="ReactTray__headline">{I18n.t('Account')}</h1>
            <button className="Button Button--icon-action ReactTray__closeBtn" type="button" onClick={this.props.closeTray}>
              <i className="icon-x"></i>
              <span className="screenreader-only">{I18n.t('Close')}</span>
            </button>
          </div>
          <ul className="ReactTray__link-list">
            <li>
              <a href="/profile">{I18n.t('Profile')}</a>
            </li>
            <li>
              <a href="/profile/settings">{I18n.t('Settings')}</a>
            </li>
            <li>
              <a href="/profile/communication">{I18n.t('Notifications')}</a>
            </li>
            <li>
              <a href="/files">{I18n.t('Files')}</a>
            </li>
            <li>
              <a href="/dashboard/eportfolios">{I18n.t('ePortfolios')}</a>
            </li>
            <li className="ReactTray__feature-list-item">
              <form ref="logoutForm" action="/logout" method="post">
                <input name="utf8" value="✓" type="hidden"/>
                <input name="_method" value="delete" type="hidden"/>
                <input name="authenticity_token" value={$.cookie('_csrf_token')} type="hidden"/>
                <a href="/logout" onClick={PreventDefault(() => this.refs.logoutForm.getDOMNode().submit())}>
                  <i className="icon-off"></i>
                  {I18n.t('Logout')}
                </a>
              </form>
            </li>
          </ul>
        </div>
      );
    }
  });

  return ProfileTray;

});
