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

import PropTypes from 'prop-types'
import React from 'react'
import sortBy from 'lodash/sortBy'

import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'

export default function RoleTrayTable({title, children}) {
  const sortedChildren = sortBy(React.Children.toArray(children), c => c.props.title)
  return (
    <View className="ic-permissions_role_tray" as="div" padding="0 0 medium 0">
      <Heading as="h3">
        <Text weight="bold">{title}</Text>
      </Heading>
      <hr aria-hidden="true" />
      {sortedChildren.map(child => (
        <span key={child.props.title}>
          {child}
          <hr aria-hidden="true" />
        </span>
      ))}
    </View>
  )
}

RoleTrayTable.propTypes = {
  title: PropTypes.string.isRequired,
  children: PropTypes.node.isRequired,
}
