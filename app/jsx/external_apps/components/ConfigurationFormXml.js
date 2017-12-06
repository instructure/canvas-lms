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

import $ from 'jquery'
import I18n from 'i18n!external_tools'
import _ from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import TextInput from '../../external_apps/components/TextInput'
import TextAreaInput from '../../external_apps/components/TextAreaInput'
import CheckboxInput from '../../external_apps/components/CheckboxInput'
import 'compiled/jquery.rails_flash_notifications'

export default React.createClass({
    displayName: 'ConfigurationFormXml',

    propTypes: {
      name                                : PropTypes.string,
      consumerKey                         : PropTypes.string,
      sharedSecret                        : PropTypes.string,
      xml                                 : PropTypes.string,
      allowMembershipServiceAccess        : PropTypes.bool,
      membershipServiceFeatureFlagEnabled : PropTypes.bool
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
      var data = {
        name:             this.refs.name.state.value,
        consumerKey:      this.refs.consumerKey.state.value,
        sharedSecret:     this.refs.sharedSecret.state.value,
        xml:              this.refs.xml.state.value,
        verifyUniqueness: 'true'
      };

      if (this.props.membershipServiceFeatureFlagEnabled) {
        data.allow_membership_service_access = this.refs.allow_membership_service_access.state.value
      }

      return data
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
                label={I18n.t('Consumer Key')}
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

          {this.renderMembershipServiceOption()}

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
