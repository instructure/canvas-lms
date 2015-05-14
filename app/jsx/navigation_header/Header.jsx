/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/navigation_header/Navigation',
  'jsx/shared/SVGWrapper',
], (I18n, React, Navigation, SVGWrapper) => {

  Navigation = React.createFactory(Navigation);
  SVGWrapper = React.createFactory(SVGWrapper);
 
  var current_user = window.ENV.current_user;

  var Header = React.createClass({
    render() {
      return (
        <div className="ic-app-header__layout">
          <div className="ic-app-header__overlay"></div>
          <div className="ic-app-header__primary">
            <div role="navigation" className="ic-app-header__main-navigation">
              <a href="/" className="ic-app-header__logomark">
                {/* TODO: @ryan Make this look right */}
                <SVGWrapper url="/images/svg-icons/svg_canvas_logomark_only.svg"/>
                <span className="screenreader-only">{I18n.t('My Dashboard')}</span>
              </a>
              {current_user && (
                <Navigation current_user={current_user}/>
              )}
            </div>
          </div>
        </div>
      );
    }
  });

  return <Header/>;
});
