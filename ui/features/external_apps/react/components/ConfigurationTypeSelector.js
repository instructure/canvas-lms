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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import React from 'react'
import PropTypes from 'prop-types'

const I18n = useI18nScope('external_tools')

export default class ConfigurationTypeSelector extends React.Component {
  static propTypes = {
    handleChange: PropTypes.func.isRequired,
    configurationType: PropTypes.string.isRequired,
  }

  componentDidMount() {
    const configSelector = $('#configuration_type_selector')
    if (configSelector && configSelector.length >= 0) {
      configSelector.change(this.props.handleChange)
    }
  }

  render() {
    return (
      <div className="ConfigurationsTypeSelector">
        <div className="form-group">
          {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
          <label>
            {I18n.t('Configuration Type')}
            <select
              id="configuration_type_selector"
              ref="configurationType"
              defaultValue={this.props.configurationType}
              className="input-block-level show-tick"
            >
              <option value="manual">{I18n.t('Manual Entry')}</option>
              <option value="url">{I18n.t('By URL')}</option>
              <option value="xml">{I18n.t('Paste XML')}</option>
              <option value="byClientId">{I18n.t('By Client ID')}</option>
              <option value="lti2">{I18n.t('By LTI 2 Registration URL')}</option>
            </select>
          </label>
        </div>
      </div>
    )
  }
}
