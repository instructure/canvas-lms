/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'

import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

export default class CustomizationOption extends React.Component {
  toggle() {
    return (
      <FormFieldGroup
        description={<ScreenReaderContent>{I18n.t('Toggle Option')}</ScreenReaderContent>}
      >
        <Checkbox
          label={<ScreenReaderContent>{this.props.label}</ScreenReaderContent>}
          variant="toggle"
          size="medium"
          name={this.props.name}
          value={this.props.name}
          onChange={this.props.onChange}
          checked={this.props.checked}
        />
      </FormFieldGroup>
    )
  }

  render() {
    return (
      <tr>
        <td>{this.props.label}</td>
        <td style={{width: '25%'}}>{this.toggle()}</td>
      </tr>
    )
  }
}

CustomizationOption.propTypes = {
  name: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  checked: PropTypes.bool.isRequired
}
