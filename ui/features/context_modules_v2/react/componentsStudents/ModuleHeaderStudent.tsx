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

import React, {useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconMiniArrowEndSolid,
  IconMiniArrowDownLine
} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import { View } from '@instructure/ui-view'

interface ModuleHeaderProps {
  id: string
  name: string
  expanded: boolean
  onToggleExpand: (id: string) => void
}

const ModuleHeader: React.FC<ModuleHeaderProps> = ({
  id,
  name,
  expanded,
  onToggleExpand,
}) => {
  const onToggleExpandRef = useCallback(() => {
    onToggleExpand(id)
  }, [onToggleExpand, id])

  return (
    <View as="div"
      background="secondary"
      borderWidth="0 0 small 0"
      borderRadius="small"
    >
      <Flex
        padding="small"
        justifyItems="space-between"
      >
        <Flex.Item>
          <Flex gap="small" alignItems="center">
            <Flex.Item>
              <IconButton
                size="small"
                withBorder={false}
                screenReaderLabel={expanded ? "Collapse module" : "Expand module"}
                renderIcon={expanded ? IconMiniArrowDownLine : IconMiniArrowEndSolid}
                withBackground={false}
                onClick={onToggleExpandRef}
              />
            </Flex.Item>
            <Flex.Item>
              <Heading level="h3">
                <TruncateText maxLines={1}>
                  {name}
                </TruncateText>
              </Heading>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleHeader
