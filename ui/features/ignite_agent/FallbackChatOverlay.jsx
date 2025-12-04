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
import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('IgniteAgent')

import React from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {IconButton} from '@instructure/ui-buttons'
import {IconXSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'

/**
 * Fallback sidebar component that renders when the agent fails to load
 * @param {object} props - The component props
 * @param {Error} props.error - The error that occurred
 * @param {Function} props.onClose - Function to call when closing the sidebar
 */
export function FallbackChatOverlay({error, onClose}) {
  return (
    <View
      as="div"
      width="320px"
      shadow="above"
      borderRadius="medium"
      background="primary"
      borderWidth="medium"
      borderColor="danger"
      position="fixed"
      insetInlineEnd="20px"
      insetBlockEnd="20px"
      style={{zIndex: 9999}}
      padding="medium"
    >
      <Flex alignItems="center" justifyItems="space-between">
        <Flex.Item shouldGrow shouldShrink>
          <Text size="medium">
            {I18n.t('An unexpected error happened while loading the Ignite Agent.')}
          </Text>
        </Flex.Item>
        <Flex.Item margin="0 0 0 medium">
          <IconButton
            onClick={onClose}
            screenReaderLabel={I18n.t('Close')}
            renderIcon={IconXSolid}
            size="small"
            color="danger"
            withBackground={true}
            withBorder={false}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}
