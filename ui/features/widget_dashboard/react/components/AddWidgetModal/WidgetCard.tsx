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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('widget_dashboard')

interface WidgetCardProps {
  type: string
  displayName: string
  description: string
  onAdd: () => void
  disabled?: boolean
}

const WidgetCard: React.FC<WidgetCardProps> = ({
  type,
  displayName,
  description,
  onAdd,
  disabled = false,
}) => {
  return (
    <View
      as="div"
      minHeight="200px"
      background="secondary"
      borderWidth="small"
      borderRadius="large"
      padding="medium"
      margin="small"
      shadow="resting"
      data-testid={`widget-card-${type}`}
      themeOverride={{
        backgroundSecondary: '#F9FAFA',
      }}
    >
      <Flex direction="column" height="100%">
        <Flex.Item shouldGrow shouldShrink overflowX="visible" overflowY="visible">
          <Flex direction="column" gap="small">
            <Flex.Item overflowX="visible" overflowY="visible">
              <Text size="large" weight="bold">
                {displayName}
              </Text>
            </Flex.Item>
            <Flex.Item height="2.3rem" overflowX="visible" overflowY="visible">
              <Text size="small" color="secondary">
                {description}
              </Text>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item margin="small 0 0 0" overflowX="visible" overflowY="visible">
          <View
            as="div"
            borderWidth="small 0 0 0"
            padding="small 0 0 0"
            themeOverride={{borderColorPrimary: '#E8EAEC'}}
          >
            <Button
              size="small"
              onClick={onAdd}
              disabled={disabled}
              renderIcon={disabled ? undefined : <IconAddLine />}
              display="block"
            >
              {disabled ? I18n.t('Added') : I18n.t('Add')}
            </Button>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default WidgetCard
