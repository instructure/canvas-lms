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

    propTypes: {
        env: React.PropTypes.object.isRequired
    },

    canAddEdit() {
      return this.props.env.PERMISSIONS && this.props.env.PERMISSIONS.create_tool_manually
    },

    render() {
      var appCenterLink = function() {
        if (!this.props.env.APP_CENTER['enabled']) {
          return '';
        }
        const baseUrl = page.base();
        return <a ref="appCenterLink" href={baseUrl} className="btn view_tools_link lm">{I18n.t('View App Center')}</a>;
      }.bind(this);

      return (
        <div className="Configurations">
          <Header>
            <AddExternalToolButton canAddEdit={this.canAddEdit()} />
            {appCenterLink()}
          </Header>
          <ExternalToolsTable canAddEdit={this.canAddEdit()}/>
        </div>
      );
    }
  });
});
