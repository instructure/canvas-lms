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

import {Flex} from '@instructure/ui-flex'
import {ReactNode} from 'react'

export const GroupedSelectLayout = (props: {
  groups: ReactNode
  items: ReactNode
  onKeyDown: (event: React.KeyboardEvent) => void
  onBlur?: (event: React.FocusEvent) => void
}) => {
  return (
    <Flex alignItems="start" gap="medium" onKeyDown={props.onKeyDown} onBlur={props.onBlur}>
      <Flex.Item direction="column" size="200px" data-testid="grouped-select-groups">
        {props.groups}
      </Flex.Item>
      <Flex.Item direction="column" shouldGrow data-testid="grouped-select-items">
        {props.items}
      </Flex.Item>
    </Flex>
  )
}
