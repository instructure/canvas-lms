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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('new_login')

type Props = {
  compact?: boolean
  icon: string
  href: string
  onClick: (event: React.MouseEvent<ViewOwnProps>) => void
  text: string
}

const Card = ({icon, text, href, onClick, compact = false}: Props) => {
  return (
    <Link
      href={href}
      onClick={onClick}
      isWithinText={false}
      display="block"
      aria-label={I18n.t('Navigate to %{text}', {text})}
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
        <Flex direction={compact ? 'row' : 'column'} wrap="wrap" gap="mediumSmall">
          <Flex.Item shouldShrink={false} align="center">
            <Img src={icon} width="3.125rem" height="3.125rem" display="block" />
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
