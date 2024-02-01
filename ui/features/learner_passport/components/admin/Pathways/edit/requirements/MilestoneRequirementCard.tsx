/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {IconDragHandleLine, IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {RequirementData} from '../../../../types'
import {RequirementTypes} from '../../../../types'
import {pluralize} from '../../../../shared/utils'

type MilestoneRequirementCardProps = {
  requirement: RequirementData
  variant: 'view' | 'edit'
  onEdit?: (requirement: RequirementData) => void
  onDelete?: (requirement: RequirementData) => void
}

const MilestoneRequirementCard = ({
  requirement,
  variant,
  onEdit,
  onDelete,
}: MilestoneRequirementCardProps) => {
  const handleEditRequirement = useCallback(() => onEdit?.(requirement), [onEdit, requirement])

  const handleDeleteRequirement = useCallback(
    () => onDelete?.(requirement),
    [onDelete, requirement]
  )
  return (
    <Flex gap="small">
      {variant === 'edit' && (
        <Flex.Item align="center">
          <IconDragHandleLine />
        </Flex.Item>
      )}
      <Flex.Item shouldGrow={true} shouldShrink={true}>
        <View as="div" background="secondary">
          <View as="div">
            <Text weight="bold">{requirement.name}</Text>
          </View>
          <View as="div">
            <Text size="small" color="secondary">
              {RequirementTypes[requirement.type]}
            </Text>
            {!requirement?.required ? (
              <>
                <Text size="small" color="secondary">
                  &nbsp;|&nbsp;
                </Text>
                <Text size="small" color="secondary">
                  Optional
                </Text>
              </>
            ) : null}
          </View>
          <View as="div" margin="0 0 x-small 0">
            <Text size="small">{requirement.description}</Text>
          </View>
          {requirement.canvas_content && (
            <Flex>
              <Flex.Item shouldGrow={true}>
                <Link href={requirement.canvas_content.url} target="_blank">
                  <Text size="small">{requirement.canvas_content.name}</Text>
                </Link>
              </Flex.Item>
              {requirement.canvas_content.learning_outcome_count > 0 && (
                <Tag
                  themeOverride={{defaultBackground: 'white'}}
                  size="small"
                  text={pluralize(
                    requirement.canvas_content.learning_outcome_count,
                    '1 outcome',
                    `${requirement.canvas_content.learning_outcome_count} outcomes`
                  )}
                />
              )}
            </Flex>
          )}
        </View>
      </Flex.Item>
      {variant === 'edit' && (
        <Flex.Item align="center">
          <View display="inline-block" margin="0 small 0 0">
            <IconButton
              screenReaderLabel="edit"
              size="small"
              withBackground={false}
              withBorder={false}
              onClick={handleEditRequirement}
            >
              <IconEditLine />
            </IconButton>
            <IconButton
              screenReaderLabel="delete"
              size="small"
              withBackground={false}
              withBorder={false}
              onClick={handleDeleteRequirement}
            >
              <IconTrashLine />
            </IconButton>
          </View>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default MilestoneRequirementCard
