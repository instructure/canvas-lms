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
import { Heading } from "@instructure/ui-heading"

export const HeaderLayout = (props: {
  size: 'small' | 'medium' | 'large'
  title: React.ReactNode
  actions: React.ReactNode
}) => {
  return (
    <Flex
      as='div'
      justifyItems='space-between'
      direction={props.size === 'large' ? 'row' : 'column'}
      gap='small'
      wrap="wrap"
    >
      <Flex.Item as='div'>
        <Heading level='h1'>
          {props.title}
        </Heading>
      </Flex.Item>
      <Flex.Item as='div' overflowY='visible'>
        {props.actions}
      </Flex.Item>
    </Flex>
  )
}
