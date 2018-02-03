/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!external_tools'
import _ from 'underscore'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'
import TextInput from '../../external_apps/components/TextInput'
import TextAreaInput from '../../external_apps/components/TextAreaInput'
import SelectInput from '../../external_apps/components/SelectInput'
import CheckboxInput from '../../external_apps/components/CheckboxInput'
import 'compiled/jquery.rails_flash_notifications'

  var PRIVACY_OPTIONS = {
    anonymous  : I18n.t('Anonymous'),
    email_only : I18n.t('E-Mail Only'),
    name_only  : I18n.t('Name Only'),
    public     : I18n.t('Public')
  };

export default React.createClass({
    displayName: 'ConfigurationFormManual',

    propTypes: {
      name                                : PropTypes.string,
      consumerKey                         : PropTypes.string,
      sharedSecret                        : PropTypes.string,
      url                                 : PropTypes.string,
      domain                              : PropTypes.string,
      privacyLevel                        : PropTypes.string,
      customFields                        : PropTypes.object,
      description                         : PropTypes.string,
      allowMembershipServiceAccess        : PropTypes.bool,
      membershipServiceFeatureFlagEnabled : PropTypes.bool
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
      var data = {
        name:             this.refs.name.state.value,
        consumerKey:      this.refs.consumerKey.state.value,
        sharedSecret:     this.refs.sharedSecret.state.value,
        url:              this.refs.url.state.value,
        domain:           this.refs.domain.state.value,
        privacyLevel:     this.refs.privacyLevel.state.value,
        customFields:     this.refs.customFields.state.value,
        description:      this.refs.description.state.value,
        verifyUniqueness: 'true'
      };

      if (this.props.membershipServiceFeatureFlagEnabled) {
        data.allow_membership_service_access = this.refs.allow_membership_service_access.state.value
      }

      return data
    },

    customFieldsToMultiLine() {
      if (!this.props.customFields) {
        return '';
      }
      return _.map(this.props.customFields, function(v, k) {
        return k+'='+v;
      }.bind(this)).join("\n")
    },

    renderMembershipServiceOption() {
      if (this.props.membershipServiceFeatureFlagEnabled) {
        return <CheckboxInput id="allow_membership_service_access"
                              ref="allow_membership_service_access"
                              label={I18n.t('Allow this tool to access the IMS Names and Role Provisioning Service')}
                              checked={this.props.allowMembershipServiceAccess}
                              errors={this.state.errors} />
      }
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
                label={I18n.t('Consumer Key')}
                errors={this.state.errors} />
            </div>
            <div className="col-xs-6">
              <TextInput
                ref="sharedSecret"
                id="sharedSecret"
                defaultValue={this.props.sharedSecret}
                placeholder={this.props.consumerKey ? I18n.t('[Unchanged]') : null} // Assume that if we have a consumer key, we have a secret
                label={I18n.t('Shared Secret')}
                errors={this.state.errors} />
            </div>
          </div>

          {this.renderMembershipServiceOption()}

          <TextInput
            ref="url"
            id="url"
            defaultValue={this.props.url ? this.props.url : ''}
            label={I18n.t('Launch URL')}
            required={true}
            errors={this.state.errors} />

          <div className="grid-row">
            <div className="col-xs-6">
              <TextInput
                ref="domain"
                id="domain"
                defaultValue={this.props.domain ? this.props.domain : ''}
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
            defaultValue={this.props.description ? this.props.description : ''}
            label={I18n.t('Description')}
            rows={6}
            errors={this.state.errors} />
        </div>
      );
    }
  });
