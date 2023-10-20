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

import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {FormField} from '@instructure/ui-form-field'

const I18n = useI18nScope('authentication_providers')

export default function AuthTypePicker({onChange, authTypes}) {
  const [selectedAuthType, setSelectedAuthType] = useState('default')

  return (
    <div>
      <FormField label={I18n.t('Add an identity provider to this account:')} id="add_auth_select">
        <select
          id="add_auth_select"
          onChange={event => {
            const authType = event.target.value
            setSelectedAuthType(authType)
            onChange(authType)
          }}
          value={selectedAuthType}
          style={{width: '100%'}}
        >
          {authTypes.map(authType => (
            <option key={authType.value} value={authType.value}>
              {authType.name}
            </option>
          ))}
        </select>
      </FormField>
    </div>
  )
}

AuthTypePicker.propTypes = {
  authTypes: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.string,
      name: PropTypes.string,
    })
  ).isRequired,
  onChange: PropTypes.func,
}

AuthTypePicker.defaultProps = {
  authTypes: [],
  onChange() {},
}
