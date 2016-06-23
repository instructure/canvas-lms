define([
  'i18n!external_tools',
  'react',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/ExternalToolsTable',
  'jsx/external_apps/components/AddExternalToolButton',
  'page'
], function(I18n, React, Header, ExternalToolsTable, AddExternalToolButton, page) {
  return React.createClass({
    displayName: 'Configurations',

    render() {
      var appCenterLink = function() {
        if (!ENV.APP_CENTER['enabled']) {
          return '';
        }
        const baseUrl = page.base();
        return <a ref="appCenterLink" href={baseUrl} className="btn view_tools_link lm">{I18n.t('View App Center')}</a>;
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
