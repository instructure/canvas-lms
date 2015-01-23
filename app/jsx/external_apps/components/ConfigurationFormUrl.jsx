/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'underscore',
  'react',
  'jsx/external_apps/components/TextInput',
  'compiled/jquery.rails_flash_notifications'
], function ($, I18n, _, React, TextInput) {

  return React.createClass({
    displayName: 'ConfigurationFormUrl',

    propTypes: {
      name         : React.PropTypes.string,
      consumerKey  : React.PropTypes.string,
      sharedSecret : React.PropTypes.string,
      configUrl    : React.PropTypes.string
    },

    getInitialState: function() {
      return {
        errors: {}
      };
    },

    isValid() {
      var fields     = ['name', 'configUrl']
        , errors     = {}
        , formErrors = [];

      fields.forEach(function(field) {
        var value = this.refs[field].state.value;
        if (!value) {
          errors[field] = I18n.t('This field is required');
          formErrors.push(I18n.t('This field "%{name}" is required.', { name: field }));
        }
      }.bind(this));
      this.setState({errors: errors});

      var isValid = true;
      if (_.keys(errors).length > 0) {
        isValid = false;
        $.screenReaderFlashError(I18n.t('There were errors with the form: %{errors}', { errors: formErrors.join(' ')}));
      }
      return isValid;
    },

    getFormData() {
      return {
        name         : this.refs.name.state.value,
        consumerKey  : this.refs.consumerKey.state.value,
        sharedSecret : this.refs.sharedSecret.state.value,
        configUrl    : this.refs.configUrl.state.value
      };
    },

    render() {
      return (
        <div className="ConfigurationFormUrl">
          <TextInput
            ref="name"
            id="name"
            defaultValue={this.props.name}
            label={I18n.t('Name')}
            required={true}
            errors={this.state.errors} />
          <div className="grid-row">
            <div className="col-xs-6">
              <TextInput
                ref="consumerKey"
                id="consumerKey"
                defaultValue={this.props.consumerKey}
                label={I18n.t('Consumer key')}
                errors={this.state.errors} />
            </div>
            <div className="col-xs-6">
              <TextInput
                ref="sharedSecret"
                id="sharedSecret"
                defaultValue={this.props.sharedSecret}
                label={I18n.t('Shared Secret')}
                errors={this.state.errors} />
            </div>
          </div>

          <TextInput
            ref="configUrl"
            id="configUrl"
            defaultValue={this.props.configUrl}
            label={I18n.t('Config URL')}
            hintText={I18n.t('Example: https://example.com/config.xml')}
            required={true}
            errors={this.state.errors} />
        </div>
      );
    }
  });
});
