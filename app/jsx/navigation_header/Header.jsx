/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/navigation_header/Navigation',
  'jsx/shared/SVGWrapper',
], (I18n, React, Navigation, SVGWrapper) => {

  var current_user = window.ENV.current_user;
  var buttonsToShow = {
    hasGroups: window.ENV.HAS_GROUPS,
    hasCourses: window.ENV.HAS_COURSES,
    hasAccounts: window.ENV.HAS_ACCOUNTS
  };
  var headerImage = window.ENV.CUSTOM_HEADER_IMAGE;
  var headerDisplayName = window.ENV.CUSTOM_HEADER_NAME;
  var helpLink = window.ENV.HELP_LINK;

  var Header = React.createClass({
    render() {
      return (
        <div className="ic-app-header__layout">
          <div className="ic-app-header__primary">
            <a href="#content" id="skip_navigation_link">{I18n.t('Skip To Content')}</a>
            <div role="navigation" className="ic-app-header__main-navigation">
              <a href="/" className="ic-app-header__logomark">
                {!!headerImage && (
                  <img src={headerImage} alt={headerDisplayName + ' logo image'} class="ic-app-header__logomark_image" />
                )}
                {!headerImage && (
                  <SVGWrapper url="/images/svg-icons/svg_canvas_logomark_only.svg"/>
                )}
                <span className="screenreader-only">{I18n.t('My Dashboard')}</span>
              </a>
              {current_user && (
                <Navigation current_user={current_user} buttonsToShow={buttonsToShow} />
              )}
            </div>
            <div role="navigation" className="ic-app-header__secondary-navigation">
              {!!helpLink && (
                <ul role="menu" className="ic-app-header__menu-list">
                  <li className="ic-app-header__menu-list-item" dangerouslySetInnerHTML={{__html: helpLink}}></li>
                </ul>
              )}
            </div>
          </div>
        </div>
      );
    }
  });

  return <Header/>;
});
