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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {filterRequirementsMet, getItemIcon, getItemTypeText, INDENT_LOOKUP} from '../utils/utils'
import {CompletionRequirement, ModuleItemContent, ModuleProgression} from '../utils/types'
import ModuleItemSupplementalInfoStudent from './ModuleItemSupplementalInfoStudent'
import ModuleItemStatusIcon from './ModuleItemStatusIcon'
import ModuleItemTitleStudent from './ModuleItemTitleStudent'

export interface ModuleItemStudentProps {
  _id: string
  title: string
  url: string
  indent: number
  position: number
  requireSequentialProgress: boolean
  index: number
  content: ModuleItemContent
  onClick?: () => void
  completionRequirements?: CompletionRequirement[]
  progression?: ModuleProgression
  smallScreen?: boolean
}

const ModuleItemStudent: React.FC<ModuleItemStudentProps> = ({
  _id,
  title,
  url,
  indent,
  position,
  requireSequentialProgress,
  content,
  onClick,
  completionRequirements,
  progression,
  smallScreen = false,
}) => {
  // Hooks must be called unconditionally
  const itemIcon = useMemo(() => (content ? getItemIcon(content, true) : null), [content])
  const itemTypeText = useMemo(() => (content ? getItemTypeText(content) : null), [content])
  const itemLeftMargin = useMemo(() => INDENT_LOOKUP[indent ?? 0], [indent])

  const requirementsMet = useMemo(() => progression?.requirementsMet || [], [progression])

  const completionRequirement = useMemo(
    () => completionRequirements?.find(req => req.id === _id),
    [completionRequirements, _id],
  )

  const filteredRequirementsMet = useMemo(() => {
    return filterRequirementsMet(requirementsMet, completionRequirements ?? []).some(
      req => req.id === _id,
    )
  }, [requirementsMet, completionRequirements, _id])

  const isCompleted = useMemo(
    () => filteredRequirementsMet && !!completionRequirement,
    [filteredRequirementsMet, completionRequirement],
  )

  // Early return after hooks
  if (!content) return null

  const cr = completionRequirement
  if (cr) {
    cr.completed = isCompleted
  }

  return (
    <View
      as="div"
      className="context_module_item"
      padding="paddingCardMedium"
      background="primary"
      borderWidth="0"
      borderRadius="large"
      overflowX="hidden"
      data-item-id={_id}
      data-position={position}
      margin="paddingCardMedium"
      minHeight="5.125rem"
      display="flex"
    >
      <Flex wrap="wrap" width="100%" gap="x-small" direction={smallScreen ? 'column' : 'row'}>
        <Flex.Item margin={itemIcon ? '0' : `0 small 0 0`} shouldGrow>
          <div style={{padding: `0 0 0 ${itemLeftMargin}`}}>
            <Flex alignItems="start" justifyItems="start" wrap="no-wrap" direction="column">
              {/* Item Title */}
              <Flex.Item shouldGrow={true}>
                <ModuleItemTitleStudent
                  title={title}
                  content={content}
                  url={url}
                  onClick={onClick}
                  position={position}
                  requireSequentialProgress={requireSequentialProgress}
                  progression={progression}
                />
              </Flex.Item>
              {/* Due Date and Points Possible */}
              {content.type !== 'SubHeader' && (
                <Flex.Item>
                  <Flex wrap="wrap" direction="column">
                    <Flex.Item>
                      <ModuleItemSupplementalInfoStudent
                        contentTagId={_id}
                        content={content}
                        itemIcon={itemIcon}
                        itemTypeText={itemTypeText}
                        completionRequirement={cr}
                        checkpoints={content.checkpoints}
                        replyToEntryRequiredCount={content.replyToEntryRequiredCount}
                      />
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
              )}
            </Flex>
          </div>
        </Flex.Item>
        {content.type !== 'SubHeader' && (
          <Flex.Item margin={smallScreen ? 'x-small 0 0 0' : '0 0 0 small'}>
            <ModuleItemStatusIcon moduleCompleted={isCompleted} content={content} />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

export default ModuleItemStudent
