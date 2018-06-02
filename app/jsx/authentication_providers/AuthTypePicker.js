/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!authentication_providers'
import Select from '@instructure/ui-core/lib/components/Select'

  class AuthTypePicker extends React.Component {

    static propTypes = {
      authTypes: PropTypes.arrayOf(PropTypes.shape({
        value: PropTypes.string,
        name: PropTypes.string
      })).isRequired,
      onChange: PropTypes.func
    };

    static defaultProps = {
      authTypes: [],
      onChange () {}
    };

    constructor (props) {
      super(props);
      this.state = {
        authType: 'default'
      };
    }

    handleChange = (event) => {
      const authType = event.target.value;
      this.setState({ authType });
      this.props.onChange(authType);
    }

    renderAuthTypeOptions () {
      return this.props.authTypes.map(authType => (
        <option
          key={authType.value}
          value={authType.value}
        >
          {authType.name}
        </option>
      ));
    }

    render () {
      const label = (
        <span className="add" style={{ display: 'block' }}>
          {I18n.t('Add an identity provider to this account:')}
        </span>
      )

      return (
        <div>
          <Select
            label={label}
            id="add_auth_select"
            onChange={this.handleChange}
            value={this.state.authType}
          >
            {this.renderAuthTypeOptions()}
          </Select>
        </div>
      );
    }

  }

export default AuthTypePicker
