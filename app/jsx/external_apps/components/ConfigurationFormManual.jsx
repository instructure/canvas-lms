/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'underscore',
  'jquery',
  'react',
  'jsx/external_apps/components/TextInput',
  'jsx/external_apps/components/TextAreaInput',
  'jsx/external_apps/components/SelectInput',
  'compiled/jquery.rails_flash_notifications'
], function(I18n, _, $, React, TextInput, TextAreaInput, SelectInput) {

  var PRIVACY_OPTIONS = {
    anonymous  : I18n.t('Anonymous'),
    email_only : I18n.t('E-Mail Only'),
    name_only  : I18n.t('Name Only'),
    public     : I18n.t('Public')
  };

  return React.createClass({
    displayName: 'ConfigurationFormManual',

    propTypes: {
      name         : React.PropTypes.string,
      consumerKey  : React.PropTypes.string,
      sharedSecret : React.PropTypes.string,
      url          : React.PropTypes.string,
      domain       : React.PropTypes.string,
      privacyLevel : React.PropTypes.string,
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
        , name       = this.refs.name.state.value   || ''
        , url        = this.refs.url.state.value    || ''
        , domain     = this.refs.domain.state.value || '';

      if (name.length == 0) {
        errors['name'] = I18n.t('This field is required');
        formErrors.push(I18n.t('This field "name" is required.'));
      }

      if (url.length == 0 && domain.length == 0) {
        errors['url'] = I18n.t('Either the url or domain should be set.');
        errors['domain'] = I18n.t('Either the url or domain should be set.');
        formErrors.push(I18n.t('Either the url or domain should be set.'));
      }

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
        name         : this.refs.name.state.value,
        consumerKey  : this.refs.consumerKey.state.value,
        sharedSecret : this.refs.sharedSecret.state.value,
        url          : this.refs.url.state.value,
        domain       : this.refs.domain.state.value,
        privacyLevel : this.refs.privacyLevel.state.value,
        customFields : this.refs.customFields.state.value,
        description  : this.refs.description.state.value
      };
    },

    customFieldsToMultiLine() {
      if (!this.props.customFields) {
        return '';
      }
      return _.map(this.props.customFields, function(v, k) {
        return k+'='+v;
      }.bind(this)).join("\n")
    },

    render() {
      return (
        <div className="ConfigurationFormManual">
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
            ref="url"
            id="url"
            defaultValue={this.props.url}
            label={I18n.t('Launch URL')}
            required={true}
            errors={this.state.errors} />

          <div className="grid-row">
            <div className="col-xs-6">
              <TextInput
                ref="domain"
                id="domain"
                defaultValue={this.props.domain}
                label={I18n.t('Domain')}
                errors={this.state.errors} />
            </div>
            <div className="col-xs-6">
              <SelectInput
                ref="privacyLevel"
                id="privacyLevel"
                defaultValue={this.props.privacyLevel}
                label={I18n.t('Privacy')}
                values={PRIVACY_OPTIONS}
                errors={this.state.errors} />
            </div>
          </div>

          <TextAreaInput
            ref="customFields"
            id="customFields"
            defaultValue={this.customFieldsToMultiLine()}
            label={I18n.t('Custom Fields')}
            hintText={I18n.t('One per line. Format: name=value')}
            rows={6}
            errors={this.state.errors} />

          <TextAreaInput
            ref="description"
            id="description"
            defaultValue={this.props.description}
            label={I18n.t('Description')}
            rows={6}
            errors={this.state.errors} />
        </div>
      );
    }
  });
});
