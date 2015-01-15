/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'jquery',
  'react',
  'jsx/external_apps/components/ConfigurationFormManual',
  'jsx/external_apps/components/ConfigurationFormUrl',
  'jsx/external_apps/components/ConfigurationFormXml',
  'jsx/external_apps/components/ConfigurationTypeSelector'
], function(I18n, $, React, ConfigurationFormManual, ConfigurationFormUrl, ConfigurationFormXml, ConfigurationTypeSelector) {

  return React.createClass({
    displayName: 'ConfigurationForm',

    propTypes: {
      configurationType: React.PropTypes.string,
      handleSubmit: React.PropTypes.func.isRequired,
      tool: React.PropTypes.object.isRequired,
      showConfigurationSelector: React.PropTypes.bool
    },

    getDefaultProps : function() {
      return {
        showConfigurationSelector: true
      };
    },

    getInitialState() {
      var _state = this.defaultState();

      if (this.props.tool) {
        _state.name         = this.props.tool.attributes.name;
        _state.consumerKey  = this.props.tool.attributes.consumer_key;
        _state.sharedSecret = this.props.tool.attributes.shared_secret;
        _state.url          = this.props.tool.attributes.url;
        _state.domain       = this.props.tool.attributes.domain;
        _state.privacy      = this.props.tool.attributes.privacy;
        _state.customFields = this.props.tool.attributes.custom_fields;
        _state.description  = this.props.tool.attributes.description;
      }

      return _state;
    },

    defaultState() {
      return {
        configurationType         : this.props.configurationType,
        showConfigurationSelector : this.props.showConfigurationSelector,
        name                      : '',
        consumerKey               : '',
        sharedSecret              : '',
        url                       : '',
        domain                    : '',
        privacy                   : '',
        customFields              : {},
        description               : '',
        configUrl                 : '',
        xml                       : ''
      };
    },

    handleSwitchConfigurationType(e) {
      this.setState({
        configurationType: $(e.target).val()
      });
    },

    handleSubmit: function(e) {
      e.preventDefault();
      var form;
      switch(this.state.configurationType) {
        case 'manual':
          form = this.refs.configurationFormManual;
          break;
        case 'url':
          form = this.refs.configurationFormUrl;
          break;
        case 'xml':
          form = this.refs.configurationFormXml;
          break;
      }

      if (form.isValid()) {
        var formData = form.getFormData();
        this.props.handleSubmit(this.state.configurationType, formData);
      } else {
        $('.ReactModal__Overlay').animate({ scrollTop: 0 }, 'slow');
      }
    },

    form() {
      if (this.state.configurationType === 'manual') {
        return (
          <ConfigurationFormManual
            ref="configurationFormManual"
            name={this.state.name}
            consumerKey={this.state.consumerKey}
            sharedSecret={this.state.sharedSecret}
            url={this.state.url}
            domain={this.state.domain}
            privacy={this.state.privacy}
            customFields={this.state.customFields}
            description={this.state.description} />
        );
      }
      if (this.state.configurationType === 'url') {
        return (
          <ConfigurationFormUrl
            ref="configurationFormUrl"
            name={this.state.name}
            consumerKey={this.state.consumerKey}
            sharedSecret={this.state.sharedSecret}
            configUrl={this.state.configUrl} />
        );
      }
      if (this.state.configurationType === 'xml') {
        return (
          <ConfigurationFormXml
            ref="configurationFormXml"
            name={this.state.name}
            consumerKey={this.state.consumerKey}
            sharedSecret={this.state.sharedSecret}
            xml={this.state.xml} />
        );
      }
    },

    configurationTypeSelector() {
      if (this.props.showConfigurationSelector) {
        return (
          <ConfigurationTypeSelector
            handleChange={this.handleSwitchConfigurationType}
            configurationType={this.props.configurationType} />
        );
      }
    },

    render() {
      return (
        <form className="ConfigurationForm">
          <div className="ReactModal__InnerSection ReactModal__Body--force-no-corners ReactModal__Body">
            {this.configurationTypeSelector()}
            <div className="formFields">
              {this.form()}
            </div>
          </div>
          <div className="ReactModal__InnerSection ReactModal__Footer">
            <div className="ReactModal__Footer-Actions">
              {this.props.children}
              <button type="submit" className="btn btn-primary" onClick={this.handleSubmit}>{I18n.t('Submit')}</button>
            </div>
          </div>
        </form>
      )
    }
  });
});
