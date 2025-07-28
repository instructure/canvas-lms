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

import { Flex } from "@instructure/ui-flex"

export const TableControlsLayout = (props: {
  breadcrumbs: React.ReactNode
  bulkActions: React.ReactNode
  size: 'small' | 'medium' | 'large'
}) => {
  return (
    <Flex
      as='div'
      justifyItems='end'
      direction={props.size === 'small' ? 'column' : 'row'}
      wrap="wrap"
    >
      <Flex.Item as='div' shouldGrow>
        {props.breadcrumbs}
      </Flex.Item>
      <Flex.Item as='div' overflowY='visible'>
        {props.bulkActions}
      </Flex.Item>
    </Flex>
  )
}
