define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper',
  'compiled/fn/preventDefault'
], (I18n, React, SVGWrapper, PreventDefault) => {

  var ProfileTray = React.createClass({

    propTypes: {
      closeTray: React.PropTypes.func.isRequired,
      userDisplayName: React.PropTypes.string.isRequired,
      userAvatarURL: React.PropTypes.string.isRequired
    },

    getInitialState () {
      return {
        logoutFormSubmitted: false
      };
    },

    submitLogoutForm() {
      if (!this.state.logoutFormSubmitted) {
        this.setState({logoutFormSubmitted: true}, () => this.refs.logoutForm.getDOMNode().submit());
      }
    },

    render() {
      return (
        <div>
          <div className="ReactTray__header ReactTray__header--is-profile" id="global_nav_profile_header">
            <div className="ReactTray-profile-header-close">
              <button
                className="Button Button--icon-action ReactTray__closeBtn"
                type="button" onClick={this.props.closeTray}>
                <i className="icon-x" aria-hidden="true"></i>
                <span className="screenreader-only">{I18n.t('Close')}</span>
              </button>
            </div>
            <div className="ic-avatar">
              <img
                src={this.props.userAvatarURL}
                alt={I18n.t('User profile picture')}
                className="ReactTray-profile-header-avatar-image"
              />
            </div>
            <h1
              className="ReactTray__headline ellipsis"
              id="global_nav_profile_display_name"
              title={this.props.userDisplayName}
            >
                {this.props.userDisplayName}
            </h1>
            <form
              ref="logoutForm"
              action="/logout"
              method="post"
              className="ReactTray-profile-header-logout-form"
            >
              <input name="utf8" value="✓" type="hidden"/>
              <input name="_method" value="delete" type="hidden"/>
              <input name="authenticity_token" value={$.cookie('_csrf_token')} type="hidden"/>
              <button
                type="submit"
                className="Button Button--small">
                {I18n.t('Logout')}
              </button>
            </form>
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
          </ul>
        </div>
      );
    }
  });

  return ProfileTray;

});
