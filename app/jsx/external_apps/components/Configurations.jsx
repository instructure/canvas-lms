/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'react',
  'react-router',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/ExternalToolsTable',
  'jsx/external_apps/components/AddExternalToolButton'
], function(I18n, React, {Link}, Header, ExternalToolsTable, AddExternalToolButton) {
  return React.createClass({
    displayName: 'Configurations',

    render() {
      var appCenterLink = function() {
        if (!ENV.APP_CENTER['enabled']) {
          return '';
        }
        return <Link ref="appCenterLink" to="appList" className="btn view_tools_link lm">{I18n.t('View App Center')}</Link>;
      }.bind(this);

      return (
        <div className="Configurations">
          <Header>
            <AddExternalToolButton />
            {appCenterLink()}
          </Header>
          <ExternalToolsTable />
        </div>
      );
    }
  });
});
