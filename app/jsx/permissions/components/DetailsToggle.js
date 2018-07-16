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

import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails/elements/ToggleDetails'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'

import propTypes from '../propTypes'

class DetailsToggle extends React.Component {
  static propTypes = {
    title: string.isRequired,
    detailItems: arrayOf(propTypes.permissionDetails).isRequired
  }

  renderDetailGroup(item) {
    return (
      <View margin="small" padding="small">
        <Text weight="bold" as="div">
          {item.title}
        </Text>
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
          <Text weight="bold" as="h3">
            {this.props.title}
          </Text>
        }
      >
        {this.props.detailItems.map(item => this.renderDetailGroup(item))}
      </ToggleDetails>
    )
  }
}

export default DetailsToggle
