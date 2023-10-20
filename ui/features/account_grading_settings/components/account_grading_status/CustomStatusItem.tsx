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
import {showConfirmationDialog} from '@canvas/feature-flags/react/ConfirmationDialog'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {EditStatusPopover} from './EditStatusPopover'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('account_grading_status')

type CustomStatusItemProps = {
  editable: boolean
  gradeStatus: GradeStatus
  isEditOpen: boolean
  handleEditSave: (color: string, name: string) => void
  handleEditStatusToggle: () => void
  handleStatusDelete: (statusId: string) => void
}
export const CustomStatusItem = ({
  editable,
  gradeStatus,
  isEditOpen,
  handleEditSave,
  handleEditStatusToggle,
  handleStatusDelete,
}: CustomStatusItemProps) => {
  const {color, name, id} = gradeStatus
  const customStatusItemRef = useRef<HTMLDivElement | undefined>(undefined)
  const confirmStatusDelete = async () => {
    const confirmed = await showConfirmationDialog({
      body: I18n.t(
        'Are you sure you want to delete this custom status? This action cannot be undone. All submissions and scores currently marked with this custom status will have their status removed.'
      ),
      confirmColor: 'danger',
      confirmText: I18n.t('Delete'),
      label: I18n.t('Delete Custom Status?'),
      size: 'small',
    })

    if (confirmed) {
      handleStatusDelete(id)
    }
  }
  return (
    <View
      as="div"
      margin="small 0 0 0"
      data-testid={`custom-status-${gradeStatus.id}`}
      id="saved-custom-status"
    >
      <GradingStatusListItem
        backgroundColor={color}
        setElementRef={ref => {
          if (ref instanceof HTMLDivElement) {
            customStatusItemRef.current = ref
          }
        }}
      >
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true} size="11rem">
            <Text weight="bold">
              <TruncateText position="middle">{name}</TruncateText>
            </Text>
          </Flex.Item>
          {editable && (
            <Flex.Item>
              <EditStatusPopover
                currentColor={color}
                customStatusName={name}
                editButtonLabel={`${I18n.t('Custom Status')} ${name}`}
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
                screenReaderLabel={I18n.t('Delete Status %{name}', {name})}
                onClick={confirmStatusDelete}
                data-testid="delete-custom-status-button"
              >
                <IconTrashSolid />
              </IconButton>
            </Flex.Item>
          )}
        </Flex>
      </GradingStatusListItem>
    </View>
  )
}
