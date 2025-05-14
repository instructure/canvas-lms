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

import React, {useMemo} from 'react'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {getItemIcon, INDENT_LOOKUP} from '../utils/utils'
import {CompletionRequirement, ModuleItemContent, ModuleProgression} from '../utils/types'
import ModuleItemSupplementalInfoStudent from './ModuleItemSupplementalInfoStudent'
import ModuleItemStatusIcon from './ModuleItemStatusIcon'
import {IconLockLine} from '@instructure/ui-icons'

export interface ModuleItemStudentProps {
  _id: string
  url: string
  indent: number
  index: number
  content: ModuleItemContent
  onClick?: () => void
  completionRequirements?: CompletionRequirement[]
  progression?: ModuleProgression
}

const ModuleItemStudent: React.FC<ModuleItemStudentProps> = ({
  _id,
  url,
  indent,
  content,
  onClick,
  completionRequirements,
  progression,
}) => {
  const itemIcon = useMemo(() => getItemIcon(content, true), [content])
  const itemLeftMargin = useMemo(() => INDENT_LOOKUP[indent ?? 0], [indent])

  return (
    <View
      as="div"
      padding="medium small medium x-small"
      background="transparent"
      borderWidth="0"
      borderRadius="medium"
      overflowX="hidden"
      data-item-id={_id}
    >
      <Flex wrap="wrap">
        <Flex.Item margin={itemIcon ? '0' : `0 small 0 0`} shouldGrow>
          <div style={{padding: `0 0 0 ${itemLeftMargin}`}}>
            <Flex alignItems="start" justifyItems="start" wrap="no-wrap" direction="column">
              {/* Item Title */}
              <Flex.Item>
                <Flex.Item shouldGrow={true}>
                  {progression?.locked ? (
                    <Flex alignItems="center">
                      <Text weight="bold" color="secondary">
                        {content?.title || 'Untitled Item'}
                      </Text>
                      <IconLockLine size="x-small" />
                    </Flex>
                  ) : (
                    <Link href={url} isWithinText={false} onClick={onClick}>
                      <Text weight="bold" color="primary">
                        {content?.title || 'Untitled Item'}
                      </Text>
                    </Link>
                  )}
                </Flex.Item>
              </Flex.Item>
              {/* Due Date and Points Possible */}
              <Flex.Item>
                <Flex wrap="wrap">
                  {/* Item Type Icon */}
                  {itemIcon && (
                    <>
                      <Flex.Item margin="0 small 0 0">
                        <View as="div">{itemIcon}</View>
                      </Flex.Item>
                      <Flex.Item margin="0 small 0 0">
                        <Text size="x-small">{content?.type}</Text>
                      </Flex.Item>
                    </>
                  )}
                  <Flex.Item>
                    <ModuleItemSupplementalInfoStudent
                      contentTagId={_id}
                      content={content}
                      completionRequirement={completionRequirements?.find(req => req.id === _id)}
                    />
                  </Flex.Item>
                </Flex>
              </Flex.Item>
            </Flex>
          </div>
        </Flex.Item>
        <Flex.Item>
          <ModuleItemStatusIcon
            itemId={_id || ''}
            completionRequirement={completionRequirements?.find(req => req.id === _id)}
            requirementsMet={progression?.requirementsMet || []}
            content={content}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleItemStudent
