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

import React, { useMemo } from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {INDENT_LOOKUP, getItemIcon} from '../utils/utils'

import ModuleItemSupplementalInfo from '../components/ModuleItemSupplementalInfo'
import {CompletionRequirement} from '../utils/types'

export interface ModuleItemStudentProps {
  _id: string
  url: string
  indent: number
  index: number
  content: {
    id?: string
    _id?: string
    title: string
    type?: string
    pointsPossible?: number
    dueAt?: string
    lockAt?: string
    unlockAt?: string
  } | null
  onClick?: () => void
  completionRequirements?: CompletionRequirement[]
}

const ModuleItemStudent: React.FC<ModuleItemStudentProps> = ({
  _id,
  url,
  indent,
  content,
  onClick,
  completionRequirements,
}) => {
  const itemIcon = useMemo(() => getItemIcon(content), [content])
  const itemLeftMargin = useMemo(() => INDENT_LOOKUP[indent ?? 0], [indent])

  return (
    <View
      as="div"
      padding="x-small medium x-small x-small"
      background="transparent"
      borderWidth="0"
      borderRadius="medium"
      overflowX="hidden"
      data-item-id={_id}
    >
      <Flex>
        {/* Item Type Icon */}
        {itemIcon && <Flex.Item margin="0 small 0 0">
          <div style={{ padding: `0 0 0 ${itemLeftMargin}` }}>
            {itemIcon}
          </div>
        </Flex.Item>}
        <Flex.Item margin={itemIcon ? '0' : `0 small 0 0`}>
          <div style={itemIcon ? {} : { padding: `0 0 0 ${itemLeftMargin}` }}>
            <Flex
              alignItems="start"
              justifyItems="start"
              wrap="no-wrap"
              direction="column"
            >
              {/* Item Title */}
              <Flex.Item>
                <Flex.Item shouldGrow={true}>
                  <Link href={url} isWithinText={false} onClick={onClick}>
                    <Text weight="bold" color='primary'>
                      {content?.title || 'Untitled Item'}
                    </Text>
                  </Link>
                </Flex.Item>
              </Flex.Item>
              {/* Due Date and Points Possible */}
              <Flex.Item>
                <ModuleItemSupplementalInfo contentTagId={_id} content={content} completionRequirement={completionRequirements?.find(req => req.id === _id)} />
              </Flex.Item>
            </Flex>
          </div>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleItemStudent
