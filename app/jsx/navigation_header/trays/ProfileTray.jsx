/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  SVGWrapper = React.createFactory(SVGWrapper);

  var ProfileTray = React.createClass({

    render() {
      return (
        <div>
          <h1>{I18n.t('Profile')}</h1>
          <ul>
            <li>
              <a href="#">{I18n.t('Profile')}</a>
            </li>
            <li>
              <a href="#">{I18n.t('Account')}</a>
            </li>
            <li>
              <a href="#">{I18n.t('Notifications')}</a>
            </li>
            <li>
              <a href="/files">{I18n.t('Files')}</a>
            </li>
            <li>
              <a href="/dashboard/eportfolios">{I18n.t('ePortfolios')}</a>
            </li>
          </ul>
        </div>
      );
    }
  });

  return ProfileTray;

});
