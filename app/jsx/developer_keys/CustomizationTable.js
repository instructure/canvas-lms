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
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Table from '@instructure/ui-elements/lib/components/Table'

import CustomizationOption from './CustomizationOption'

export default class CustomizationTable extends React.Component {
  get fixedWidthColumn() {
    return {
      width: '25%'
    }
  }

  optionIsChecked(option) {
    if (this.props.type === 'scope') {
      return this.props.selectedOptions.includes(option)
    }
    return !this.props.selectedOptions.includes(option)
  }

  render() {
    return (
      <Table
        margin="0 0 medium 0"
        caption={<ScreenReaderContent>{this.props.name}</ScreenReaderContent>}
      >
        <thead>
          <tr>
            <th scope="col">{this.props.name}</th>
            <th scope="col" style={this.fixedWidthColumn}>
              {I18n.t('State')}
            </th>
          </tr>
        </thead>
        <tbody>
          {this.props.options.map(option => (
            <CustomizationOption
              name={option}
              label={option}
              onChange={this.props.onOptionToggle}
              type={this.props.type}
              checked={this.optionIsChecked(option)}
              key={`customization:${option}`}
            />
          ))}
        </tbody>
      </Table>
    )
  }
}

CustomizationTable.propTypes = {
  name: PropTypes.string.isRequired,
  type: PropTypes.string.isRequired,
  options: PropTypes.arrayOf(PropTypes.string),
  selectedOptions: PropTypes.arrayOf(PropTypes.string),
  onOptionToggle: PropTypes.func.isRequired
}
