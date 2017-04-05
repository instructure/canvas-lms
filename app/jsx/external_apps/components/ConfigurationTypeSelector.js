import I18n from 'i18n!external_tools'
import $ from 'jquery'
import React from 'react'
import Header from 'jsx/external_apps/components/Header'
import ExternalToolsTable from 'jsx/external_apps/components/ExternalToolsTable'
export default React.createClass({
    displayName: 'ConfigurationTypeSelector',

    propTypes: {
      handleChange: React.PropTypes.func.isRequired,
      configurationType: React.PropTypes.string.isRequired
    },

    componentDidMount() {
      var configSelector = $("#configuration_type_selector");
      if (configSelector && configSelector.length >= 0) {
        configSelector.change(this.props.handleChange);
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
                <option value="lti2">{I18n.t('By LTI 2 Registration URL')}</option>
              </select>
            </label>
          </div>
        </div>
      );
    }
  });
