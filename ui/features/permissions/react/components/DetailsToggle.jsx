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

import React from 'react'
import {arrayOf, string} from 'prop-types'

import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import propTypes from '@canvas/permissions/react/propTypes'

class DetailsToggle extends React.Component {
  static propTypes = {
    title: string.isRequired,
    detailItems: arrayOf(propTypes.permissionDetails).isRequired,
  }

  renderDetailGroup(item, key) {
    return (
      <View key={key} margin="none small none small" padding="small">
        {item.title && (
          <Text weight="bold" as="div">
            {item.title}
          </Text>
        )}
        <Text weight="normal" as="div">
          {item.description}
        </Text>
      </View>
    )
  }

  render() {
    if (!this.props.detailItems || this.props.detailItems.length === 0) {
      return null
    }
    return (
      <ToggleDetails
        summary={
          <Text weight="bold" transform="uppercase" as="h3">
            {this.props.title}
          </Text>
        }
      >
        {this.props.detailItems.map((item, index) => this.renderDetailGroup(item, index))}
      </ToggleDetails>
    )
  }
}

export default DetailsToggle
