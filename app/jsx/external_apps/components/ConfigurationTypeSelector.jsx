/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'react',
  'react-router',
  'jsx/external_apps/components/Header',
  'jsx/external_apps/components/ExternalToolsTable',
  'vendor/bootstrap/bootstrap-dropdown',
  'vendor/bootstrap-select/bootstrap-select'
], function(I18n, React, {Link}, Header, ExternalToolsTable) {
  return React.createClass({
    displayName: 'ConfigurationTypeSelector',

    propTypes: {
      handleChange: React.PropTypes.func.isRequired,
      configurationType: React.PropTypes.string.isRequired
    },

    componentDidMount() {
      var configSelector = $("#configuration_type_selector");
      if (configSelector && configSelector.length >= 0) {
        configSelector.change(this.props.handleChange);
        configSelector.selectpicker();
      }
    },

    render() {
      return (
        <div className="ConfigurationsTypeSelector">
          <div className="form-group">
            <label>
              {I18n.t('Configuration Type')}
              <select id='configuration_type_selector' ref="configurationType" aria-haspopup="true" defaultValue={this.props.configurationType} className="input-block-level show-tick">
                <option value="manual">{I18n.t('Manual Entry')}</option>
                <option value="url">{I18n.t('By URL')}</option>
                <option value="xml">{I18n.t('Paste XML')}</option>
                { ENV.ENABLE_LTI2 ? <option value="lti2">{I18n.t('By LTI 2 Registration URL')}</option> : null }
              </select>
            </label>
          </div>
        </div>
      );
    }
  });
});