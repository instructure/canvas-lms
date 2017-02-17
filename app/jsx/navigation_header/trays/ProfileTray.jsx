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
      userAvatarURL: React.PropTypes.string.isRequired,
      profileEnabled: React.PropTypes.bool.isRequired,
      eportfoliosEnabled: React.PropTypes.bool.isRequired
    },

    render() {
      return (
        <div className='profile-tray'>
          <div className="ic-NavMenu__header ic-NavMenu__header--is-profile" id="global_nav_profile_header">
            <div className="ic-NavMenu-profile-header-close">
              <button
                className="Button Button--icon-action ic-NavMenu__closeButton"
                type="button" onClick={this.props.closeTray}>
                <i className="icon-x" aria-hidden="true"></i>
                <span className="screenreader-only">{I18n.t('Close')}</span>
              </button>
            </div>
            <div className="ic-avatar">
              <img
                src={this.props.userAvatarURL}
                alt={I18n.t('User profile picture')}
                className="ic-NavMenu-profile-header-avatar-image"
              />
            </div>
            <h1
              className="ic-NavMenu__headline ellipsis"
              id="global_nav_profile_display_name"
              title={this.props.userDisplayName}
            >
                {this.props.userDisplayName}
            </h1>
            <form
              ref="logoutForm"
              action="/logout"
              method="post"
              className="ic-NavMenu-profile-header-logout-form"
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
          <ul className="ic-NavMenu__link-list">
            {this.props.profileEnabled &&
              <li className="ic-NavMenu-list-item">
                <a href="/profile" className="ic-NavMenu-list-item__link">{I18n.t('Profile')}</a>
              </li>
            }
            <li className="ic-NavMenu-list-item">
              <a href="/profile/settings" className="ic-NavMenu-list-item__link">{I18n.t('Settings')}</a>
            </li>
            <li className="ic-NavMenu-list-item">
              <a href="/profile/communication" className="ic-NavMenu-list-item__link">{I18n.t('Notifications')}</a>
            </li>
            <li className="ic-NavMenu-list-item">
              <a href="/files" className="ic-NavMenu-list-item__link">{I18n.t('Files')}</a>
            </li>
            {this.props.eportfoliosEnabled &&
              <li className="ic-NavMenu-list-item">
                <a href="/dashboard/eportfolios" className="ic-NavMenu-list-item__link">{I18n.t('ePortfolios')}</a>
              </li>
            }
          </ul>
        </div>
      );
    }
  });

  return ProfileTray;

});
