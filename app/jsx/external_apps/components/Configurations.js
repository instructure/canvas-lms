import I18n from 'i18n!external_tools'
import React from 'react'
import Header from 'jsx/external_apps/components/Header'
import ExternalToolsTable from 'jsx/external_apps/components/ExternalToolsTable'
import AddExternalToolButton from 'jsx/external_apps/components/AddExternalToolButton'
import page from 'page'
export default React.createClass({
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
