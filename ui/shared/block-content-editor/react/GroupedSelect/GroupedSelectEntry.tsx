/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import './grouped-select.css'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

export const GroupedSelectEntry = (props: {
  variant: 'item' | 'group'
  title: string
  active: boolean
  onClick: () => void
}) => {
  const isItem = props.variant === 'item'
  const className = isItem ? 'grouped-select-item' : 'grouped-select-group'
  return (
    <View
      as="div"
      className={`${className} ${props.active ? 'selected' : ''}`}
      onClick={props.onClick}
    >
      <Text variant="content">{props.title}</Text>
    </View>
  )
}
