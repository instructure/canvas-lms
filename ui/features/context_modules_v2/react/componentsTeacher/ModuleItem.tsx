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

import React, {useMemo, useState} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {
  IconDragHandleLine,
  IconExternalLinkLine,
} from '@instructure/ui-icons'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import {INDENT_LOOKUP, getItemIcon} from '../utils/utils'

import ModuleItemActionPanel from './ModuleItemActionPanel'
import ModuleItemSupplementalInfo from '../components/ModuleItemSupplementalInfo'
import {CompletionRequirement, MasteryPathsData} from '../utils/types'

export interface ModuleItemProps {
  id: string
  _id: string
  url: string
  indent: number
  moduleId: string
  index: number
  content: {
    id?: string
    _id?: string
    title: string
    type?: string
    pointsPossible?: number
    published?: boolean
    canUnpublish?: boolean
    dueAt?: string
    lockAt?: string
    unlockAt?: string
  } | null
  onClick?: () => void
  published?: boolean
  canUnpublish?: boolean
  dragHandleProps?: any // For react-beautiful-dnd
  onEdit?: (id: string) => void
  onDuplicate?: (id: string) => void
  onRemove?: (id: string) => void
  completionRequirements?: CompletionRequirement[]
}

const ModuleItem: React.FC<ModuleItemProps> = ({
  _id,
  id,
  url,
  moduleId,
  indent,
  content,
  onClick,
  completionRequirements,
  published,
  canUnpublish,
  dragHandleProps,
}) => {
  const getMasteryPathsData = (): MasteryPathsData | null => {
    if (!content || !content._id || !CyoeHelper.isEnabled()) {
      return null
    }

    let data = CyoeHelper.getItemData(content._id, true)

    if (!data?.isCyoeAble && !data?.isTrigger && !data?.isReleased && content.id) {
      data = CyoeHelper.getItemData(content.id, true)
    }

    return {
      isCyoeAble: !!data?.isCyoeAble,
      isTrigger: !!data?.isTrigger,
      isReleased: !!data?.isReleased,
      releasedLabel: data?.releasedLabel || null
    }
  }

  const masteryPathsData = getMasteryPathsData()

  const itemIcon = useMemo(() => getItemIcon(content), [content])

  const itemLeftMargin = useMemo(() => INDENT_LOOKUP[indent ?? 0], [indent])

  return (
    <View
      as="div"
      padding="small medium small xxx-small"
      background="transparent"
      overflowX="hidden"
      data-item-id={_id}
    >
      <Flex wrap='wrap'>
        <Flex.Item margin='0 small 0 0'>
          {/* Drag Handle */}
          <div {...dragHandleProps}>
            <IconDragHandleLine />
          </div>
        </Flex.Item>
        <Flex.Item>
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
                        <Text weight={content?.type === 'ExternalUrl' ? 'normal' : 'bold'} color={content?.type === 'ExternalUrl' ? 'brand' : 'primary'}>
                          {content?.title || 'Untitled Item'} {/* FIXME:show when link opens a new tab{content?.type === 'ExternalUrl' && <IconExternalLinkLine size="x-small" color="brand" />}*/}
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
        </Flex.Item>
        <Flex.Item shouldGrow>
          <ModuleItemActionPanel
            moduleId={moduleId}
            itemId={_id}
            id={id}
            indent={indent}
            content={content}
            published={published || false}
            canBeUnpublished={canUnpublish || false}
            masteryPathsData={masteryPathsData}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default ModuleItem
