/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'underscore',
  'jquery',
  'react',
  'jsx/external_apps/mixins/FormHelpersMixin',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, _, $, React, FormHelpersMixin) {

  var PRIVACY_OPTIONS = {
    anonymous  : I18n.t('Anonymous'),
    email_only : I18n.t('E-Mail Only'),
    name_only  : I18n.t('Name Only'),
    public     : I18n.t('Public')
  };

  return React.createClass({
    displayName: 'ConfigurationFormManual',

    mixins: [FormHelpersMixin],

    propTypes: {
      name         : React.PropTypes.string,
      consumerKey  : React.PropTypes.string,
      sharedSecret : React.PropTypes.string,
      url          : React.PropTypes.string,
      domain       : React.PropTypes.string,
      privacy      : React.PropTypes.string,
      customFields : React.PropTypes.object,
      description  : React.PropTypes.string
    },

    getInitialState() {
      return {
        errors: {}
      }
    },

    isValid() {
      var errors     = {}
        , formErrors = []
        , nameNode   = this.refs.name.getDOMNode()
        , urlNode    = this.refs.url.getDOMNode()
        , domainNode = this.refs.domain.getDOMNode()
        , name       = nameNode.value
        , url        = urlNode.value
        , domain     = domainNode.value;

      if (name.length == 0) {
        errors['name'] = I18n.t('This field is required');
        formErrors.push(I18n.t('This field "name" is required.'));
      }

      if (url.length == 0 && domain.length == 0) {
        errors['url'] = I18n.t('Either the url or domain should be set.');
        errors['domain'] = I18n.t('Either the url or domain should be set.');
        formErrors.push(I18n.t('Either the url or domain should be set.'));
      }

      nameNode.setAttribute('aria-invalid', _.has(errors, 'name'));
      urlNode.setAttribute('aria-invalid', _.has(errors, 'url'));
      domainNode.setAttribute('aria-invalid', _.has(errors, 'domain'));

      this.setState({ errors: errors });

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
        url          : this.refs.url.getDOMNode().value,
        domain       : this.refs.domain.getDOMNode().value,
        privacy      : this.refs.privacy.getDOMNode().value,
        customFields : this.refs.customFields.getDOMNode().value,
        description  : this.refs.description.getDOMNode().value
      };
    },

    customFields() {
      return _.map(this.props.customFields, function(v, k) {
        return k+'='+v;
      }.bind(this)).join("\n")
    },

    render() {

      return (
        <div className="ConfigurationFormManual">
          {this.renderTextInput('name', this.props.name, I18n.t('Name'), null, true)}
          <div className="grid-row">
            <div className="col-xs-6">
            {this.renderTextInput('consumerKey', this.props.consumerKey, I18n.t('Consumer Key'))}
            </div>
            <div className="col-xs-6">
            {this.renderTextInput('sharedSecret', this.props.sharedSecret, I18n.t('Shared Secret'))}
            </div>
          </div>
          {this.renderTextInput('url', this.props.url, I18n.t('Launch URL'))}
          <div className="grid-row">
            <div className="col-xs-6">
            {this.renderTextInput('domain', this.props.domain, I18n.t('Domain'))}
            </div>
            <div className="col-xs-6">
            {this.renderSelect('privacy', this.props.privacy, I18n.t('Privacy'), PRIVACY_OPTIONS)}
            </div>
          </div>
          {this.renderTextarea('customFields', this.customFields(), I18n.t('Custom Fields'), I18n.t('One per line. Format: name=value'), 6)}
          {this.renderTextarea('description', this.props.description, I18n.t('Description'), '', 6)}
        </div>
      );
    }
  });
});
