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
    displayName: 'ConfigurationFormXml',

    mixins: [FormHelpersMixin],

    propTypes: {
      name         : React.PropTypes.string.isRequired,
      consumerKey  : React.PropTypes.string.isRequired,
      sharedSecret : React.PropTypes.string.isRequired,
      xml          : React.PropTypes.string.isRequired
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
        var value = this.refs[field].getDOMNode().value.trim();
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
        name         : this.refs.name.getDOMNode().value,
        consumerKey  : this.refs.consumerKey.getDOMNode().value,
        sharedSecret : this.refs.sharedSecret.getDOMNode().value,
        xml          : this.refs.xml.getDOMNode().value
      };
    },

    render() {
      return (
        <div className="ConfigurationFormXml">
          <div className="form-group">
            {this.renderTextInput('name', this.props.name, I18n.t('Name'))}
          </div>
          <div className="form-group">
            <div className="grid-row">
              <div className="col-xs-6">
                {this.renderTextInput('consumerKey', this.props.consumerKey, I18n.t('Consumer Key'))}
              </div>
              <div className="col-xs-6">
                {this.renderTextInput('sharedSecret', this.props.sharedSecret, I18n.t('Shared Secret'))}
              </div>
            </div>
          </div>
          <div className="form-group">
            {this.renderTextarea('xml', this.props.xml, I18n.t('XML Configuration'), '', 12)}
          </div>
        </div>
      );
    }
  });
});
