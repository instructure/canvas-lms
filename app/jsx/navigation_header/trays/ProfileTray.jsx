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
            <li className="ReactTray-list-item">
              <a href="/profile" className="ReactTray-list-item__link">{I18n.t('Profile')}</a>
            </li>
            <li className="ReactTray-list-item">
              <a href="/profile/settings" className="ReactTray-list-item__link">{I18n.t('Settings')}</a>
            </li>
            <li className="ReactTray-list-item">
              <a href="/profile/communication" className="ReactTray-list-item__link">{I18n.t('Notifications')}</a>
            </li>
            <li className="ReactTray-list-item">
              <a href="/files" className="ReactTray-list-item__link">{I18n.t('Files')}</a>
            </li>
            <li className="ReactTray-list-item">
              <a href="/dashboard/eportfolios" className="ReactTray-list-item__link">{I18n.t('ePortfolios')}</a>
            </li>
            <li className="ReactTray-list-item ReactTray-list-item--feature-item">
              <form ref="logoutForm" action="/logout" method="post">
                <input name="utf8" value="✓" type="hidden"/>
                <input name="_method" value="delete" type="hidden"/>
                <input name="authenticity_token" value={$.cookie('_csrf_token')} type="hidden"/>
                <a 
                  href="/logout"
                  className="ReactTray-list-item__link"
                  onClick={PreventDefault(() => this.refs.logoutForm.getDOMNode().submit())}>
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
