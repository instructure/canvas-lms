/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

export default function DescriptionDisplay(props) {
  const titleOptions = !props.unlocked_at ? {color: 'secondary'} : {color: 'brand'}
  const descOptions = !props.unlocked_at ? {color: 'secondary'} : {color: 'primary'}
  return (
    <Flex direction="column">
      <Flex.Item margin="xxx-small">
        <Text size="large" weight="bold" {...titleOptions}>
          {props.name}
        </Text>
      </Flex.Item>
      <Flex.Item margin="xxx-small">
        <Text size={props.descriptionSize || 'small'} {...descOptions}>
          {props.description}
        </Text>
      </Flex.Item>
    </Flex>
  )
}
