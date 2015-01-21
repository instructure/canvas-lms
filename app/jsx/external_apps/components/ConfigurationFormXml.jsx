/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'underscore',
  'old_unsupported_dont_use_react',
  'jsx/external_apps/components/TextInput',
  'jsx/external_apps/components/TextAreaInput',
  'compiled/jquery.rails_flash_notifications'
], function ($, I18n, _, React, TextInput, TextAreaInput) {

  return React.createClass({
    displayName: 'ConfigurationFormXml',

    propTypes: {
      name         : React.PropTypes.string,
      consumerKey  : React.PropTypes.string,
      sharedSecret : React.PropTypes.string,
      xml          : React.PropTypes.string
    },

    getInitialState: function() {
      return {
        errors: {}
      };
    },

    isValid() {
      var fields     = ['name', 'xml']
        , errors     = {}
        , formErrors = [];

      var errors = {};
      fields.forEach(function(field) {
        var value = this.refs[field].state.value;
        if (!value) {
          errors[field] = 'This field is required';
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
        xml          : this.refs.xml.state.value
      };
    },

    render() {
      return (
        <div className="ConfigurationFormXml">
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
          <TextAreaInput
            ref="xml"
            id="xml"
            defaultValue={this.props.xml}
            label={I18n.t('XML Configuration')}
            rows={12}
            errors={this.state.errors} />
        </div>
      );
    }
  });
});
