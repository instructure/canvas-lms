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

import React, {useRef} from 'react'
import {GradingStatusListItem} from '@canvas/grading-status-list-item'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'
import {IconButton} from '@instructure/ui-buttons'
// @ts-expect-error
import {IconTrashSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
// @ts-expect-error
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {EditStatusPopover} from './EditStatusPopover'
import {Flex} from '@instructure/ui-flex'

const {Item: FlexItem} = Flex as any

type CustomStatusItemProps = {
  gradeStatus: GradeStatus
  isEditOpen: boolean
  handleEditSave: (color: string, name: string) => void
  handleEditStatusToggle: () => void
  handleStatusDelete: (statusId: string) => void
}
export const CustomStatusItem = ({
  gradeStatus,
  isEditOpen,
  handleEditSave,
  handleEditStatusToggle,
  handleStatusDelete,
}: CustomStatusItemProps) => {
  const {color, name, id} = gradeStatus
  const customStatusItemRef = useRef<HTMLDivElement | undefined>(undefined)
  return (
    <View as="div" margin="small 0 0 0" data-testid={`custom-status-${gradeStatus.id}`}>
      <GradingStatusListItem
        backgroundColor={color}
        setElementRef={ref => (customStatusItemRef.current = ref)}
      >
        <Flex>
          <FlexItem shouldGrow={true} shouldShrink={true} size="11rem">
            <Text weight="bold">
              <TruncateText position="middle">{name}</TruncateText>
            </Text>
          </FlexItem>
          <FlexItem>
            <EditStatusPopover
              currentColor={color}
              customStatusName={name}
              handleEditSave={handleEditSave}
              isCustomStatus={true}
              isOpen={isEditOpen}
              handleEditStatusToggle={handleEditStatusToggle}
              positionTarget={customStatusItemRef.current}
            />

            <IconButton
              size="small"
              withBackground={false}
              withBorder={false}
              screenReaderLabel="Delete Status"
              onClick={() => handleStatusDelete(id)}
            >
              <IconTrashSolid />
            </IconButton>
          </FlexItem>
        </Flex>
      </GradingStatusListItem>
    </View>
  )
}
