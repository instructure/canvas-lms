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
// @ts-expect-error
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {EditStatusPopover} from './EditStatusPopover'
import {GradeStatus} from '../../types/gradingStatus'
import {GradingStatusListItem} from '@canvas/grading-status-list-item'

type StandardStatusItemProps = {
  gradeStatus: GradeStatus
  isEditOpen: boolean
  handleEditSave: (color: string) => void
  handleEditStatusToggle: () => void
}
export const StandardStatusItem = ({
  gradeStatus,
  isEditOpen,
  handleEditSave,
  handleEditStatusToggle,
}: StandardStatusItemProps) => {
  const {color, name} = gradeStatus
  const standardStatusRef = useRef<HTMLDivElement | undefined>(undefined)

  return (
    <View as="div" margin="small 0 0 0" data-testid={`standard-status-${gradeStatus.id}`}>
      <GradingStatusListItem
        backgroundColor={color}
        setElementRef={ref => (standardStatusRef.current = ref)}
      >
        <Grid vAlign="middle">
          <Grid.Row>
            <Grid.Col>
              <Text weight="bold">{name}</Text>
            </Grid.Col>
            <Grid.Col width="auto">
              <EditStatusPopover
                currentColor={color}
                isOpen={isEditOpen}
                handleEditSave={handleEditSave}
                handleEditStatusToggle={handleEditStatusToggle}
                positionTarget={standardStatusRef.current}
              />
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </GradingStatusListItem>
    </View>
  )
}
