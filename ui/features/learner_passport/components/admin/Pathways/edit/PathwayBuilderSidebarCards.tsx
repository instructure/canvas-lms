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
import {IconButton} from '@instructure/ui-buttons'
import {IconDragHandleLine, IconEditLine, IconTrashLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData, MilestoneData} from '../../../types'

type PathwayCardProps = {
  step: PathwayDetailData
  onEdit: () => void
}

const PathwayCard = ({step, onEdit}: PathwayCardProps) => {
  const handleEdit = useCallback(() => {
    onEdit()
  }, [onEdit])

  return (
    <View
      as="div"
      background="primary-inverse"
      borderRadius="large"
      padding="small"
      textAlign="start"
    >
      <Flex as="div" gap="small">
        {step.image_url && (
          <img src={step.image_url} alt="" style={{height: '42px', display: 'inline-block'}} />
        )}
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text as="div" fontStyle="italic" size="x-small">
            End of pathway
          </Text>
          <Text as="div" weight="bold" size="x-small">
            <TruncateText>{step.title}</TruncateText>
          </Text>
        </Flex.Item>
        <IconButton
          color="primary-inverse"
          screenReaderLabel="edit pathway"
          size="small"
          withBackground={false}
          withBorder={false}
          onClick={handleEdit}
        >
          <IconEditLine />
        </IconButton>
      </Flex>
    </View>
  )
}

type MilestoneCardProps = {
  step: MilestoneData
  variant: 'root' | 'child'
  onEdit: (id: string) => void
  onDelete?: (id: string) => void
}

const MilestoneCard = ({step, variant, onEdit, onDelete}: MilestoneCardProps) => {
  return (
    <View
      as="div"
      background="primary"
      borderWidth="small"
      borderRadius="large"
      padding="small"
      textAlign="start"
      width="auto"
    >
      <Flex as="div" gap="small">
        {variant === 'child' && <IconDragHandleLine />}
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <Text as="div" weight="bold" size="x-small">
            <TruncateText>{step.title}</TruncateText>
          </Text>
          <Text as="div" size="x-small">
            {step.next_milestones.filter(m => m !== 'blank').length} prerequisites
          </Text>
        </Flex.Item>
        <Flex.Item>
          <IconButton
            screenReaderLabel="edit step"
            size="small"
            withBackground={false}
            withBorder={false}
            onClick={() => onEdit(step.id)}
          >
            <IconEditLine />
          </IconButton>
          {onDelete && (
            <IconButton
              margin="0 0 0 x-small"
              screenReaderLabel="delete step"
              size="small"
              withBackground={false}
              withBorder={false}
              onClick={() => onDelete(step.id)}
            >
              <IconTrashLine />
            </IconButton>
          )}
        </Flex.Item>
      </Flex>
    </View>
  )
}

const BlankPathwayCard = () => {
  return (
    <View
      as="div"
      background="secondary"
      borderWidth="small"
      borderRadius="medium"
      width="408px"
      height="56px"
    />
  )
}

export {PathwayCard, MilestoneCard, BlankPathwayCard}
