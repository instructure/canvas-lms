/** @jsx React.DOM */

define([
  'jquery',
  'i18n!external_tools',
  'underscore',
  'react',
  'jsx/external_apps/mixins/FormHelpersMixin',
  'compiled/jquery.rails_flash_notifications'
], function ($, I18n, _, React, FormHelpersMixin) {

  return React.createClass({
    displayName: 'ConfigurationFormUrl',

    mixins: [FormHelpersMixin],

    propTypes: {
      name         : React.PropTypes.string.isRequired,
      consumerKey  : React.PropTypes.string.isRequired,
      sharedSecret : React.PropTypes.string.isRequired,
      configUrl    : React.PropTypes.string.isRequired
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
        var value = this.refs[field].getDOMNode().value.trim();
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
        name         : this.refs.name.getDOMNode().value,
        consumerKey  : this.refs.consumerKey.getDOMNode().value,
        sharedSecret : this.refs.sharedSecret.getDOMNode().value,
        configUrl    : this.refs.configUrl.getDOMNode().value
      };
    },

    render() {
      return (
        <div className="ConfigurationFormUrl">
          {this.renderTextInput('name', this.props.name, I18n.t('Name'))}
          <div className="grid-row">
            <div className="col-xs-6">
              {this.renderTextInput('consumerKey', this.props.consumerKey, I18n.t('Consumer Key'))}
            </div>
            <div className="col-xs-6">
              {this.renderTextInput('sharedSecret', this.props.sharedSecret, I18n.t('Shared Secret'))}
            </div>
          </div>
          {this.renderTextInput('configUrl', this.props.configUrl, I18n.t('Config URL'), I18n.t('Example: https://example.com/config.xml'))}
        </div>
      );
    }
  });
});
