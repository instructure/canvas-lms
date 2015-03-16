/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'react',
  'react-router',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/ExternalToolsTable'
], function(I18n, React, {Link}, Header, ExternalToolsTable) {
  return React.createClass({
    displayName: 'ConfigurationTypeSelector',

    propTypes: {
      handleChange: React.PropTypes.func.isRequired,
      configurationType: React.PropTypes.string.isRequired
    },

    render() {
      return (
        <div className="ConfigurationsTypeSelector">
          <div className="form-group">
            <label>{I18n.t('Configuration Type')}</label>
            <select ref="configurationType" defaultValue={this.props.configurationType} className="form-control input-block-level" onChange={this.props.handleChange}>
              <option value="manual">{I18n.t('Manual Entry')}</option>
              <option value="url">{I18n.t('By URL')}</option>
              <option value="xml">{I18n.t('Paste XML')}</option>
              { ENV.ENABLE_LTI2 ? <option value="lti2">{I18n.t('By LTI 2 Registration URL')}</option> : null }
            </select>
          </div>
        </div>
      );
    }
  });
});