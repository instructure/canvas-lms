/** @jsx React.DOM */

define([
  'i18n!external_tools',
  'underscore',
  'old_unsupported_dont_use_react',
  'jsx/external_apps/components/TextInput'
], function (I18n, _, React, TextInput) {

  return React.createClass({
    displayName: 'ConfigurationFormLti2',

    propTypes: {
      registrationUrl : React.PropTypes.string.isRequired
    },

    getInitialState: function() {
      return {
        errors: {}
      };
    },

    isValid() {
      if (!this.refs.registrationUrl.state.value) {
        this.setState({ errors: { registrationUrl: I18n.t('This field is required') }});
        return false;
      } else {
        return true;
      }
    },

    getFormData() {
      return {
        registrationUrl : this.refs.registrationUrl.state.value
      };
    },

    render() {
      return (
        <div className="ConfigurationFormLti2">
          <TextInput
            ref="registrationUrl"
            id="registrationUrl"
            defaultValue={this.props.registrationUrl}
            label={I18n.t('Registration URL')}
            hintText={I18n.t('Example: https://lti-tool-provider-example.herokuapp.com/register')}
            required={true}
            errors={this.state.errors} />
        </div>
      );
    }
  });
});
