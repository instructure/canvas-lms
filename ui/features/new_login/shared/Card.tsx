/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import React from 'react'

type Props = {
  compact?: boolean
  href: string
  icon: string
  label: string
  onClick: (event: React.MouseEvent<ViewOwnProps>) => void
  testId?: string
  text: string
}

const Card = ({compact = false, href, icon, label, onClick, testId, text}: Props) => {
  return (
    <Link
      aria-label={label}
      data-testid={testId}
      display="block"
      href={href}
      isWithinText={false}
      onClick={onClick}
    >
      <View
        as="div"
        background="primary"
        borderWidth="small"
        display="block"
        padding={compact ? 'medium' : 'large medium'}
        shadow="resting"
        width="100%"
      >
        <Flex direction={compact ? 'row' : 'column'} gap="mediumSmall" wrap="wrap">
          <Flex.Item shouldShrink={false} align="center">
            <Img
              data-testid="card-icon"
              display="block"
              height="3.125rem"
              src={icon}
              width="3.125rem"
            />
          </Flex.Item>

          <Flex.Item shouldGrow={true} textAlign="center">
            <Text weight="bold">{text}</Text>
          </Flex.Item>
        </Flex>
      </View>
    </Link>
  )
}

export default Card
