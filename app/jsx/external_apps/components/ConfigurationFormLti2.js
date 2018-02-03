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
import React from 'react'
import PropTypes from 'prop-types'
import TextInput from '../../external_apps/components/TextInput'

export default React.createClass({
    displayName: 'ConfigurationFormLti2',

    propTypes: {
      registrationUrl : PropTypes.string.isRequired
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
            name="tool_consumer_url"
            defaultValue={this.props.registrationUrl}
            label={I18n.t('Registration URL')}
            hintText={I18n.t('Example: https://lti-tool-provider-example.herokuapp.com/register')}
            required={true}
            errors={this.state.errors} />
        </div>
      );
    }
  });
