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
import {colorPickerColors, GradingStatusListItem} from '@canvas/grading-status-list-item'
import {useScope as useI18nScope} from '@canvas/i18n'
// @ts-expect-error
import {IconAddSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {EditStatusPopover} from './EditStatusPopover'

const I18n = useI18nScope('account_grading_status')

type CustomStatusNewItemProps = {
  index: number
  isEditOpen: boolean
  handleEditStatusToggle: () => void
  handleSave: (color: string, statusName: string) => void
}
export const CustomStatusNewItem = ({
  index,
  isEditOpen,
  handleEditStatusToggle,
  handleSave,
}: CustomStatusNewItemProps) => {
  const customStatusItemRef = useRef<HTMLDivElement | undefined>(undefined)

  return (
    <View as="div" margin="small 0 0 0" data-testid={`custom-status-new-${index}`}>
      <GradingStatusListItem
        backgroundColor="transparent"
        borderColor="info"
        borderStyle="dashed"
        borderWidth="small"
        cursor="pointer"
        setElementRef={ref => (customStatusItemRef.current = ref)}
      >
        <View
          as="span"
          margin="0 0 0 x-small"
          display="inline-block"
          width="100%"
          onClick={() => handleEditStatusToggle()}
        >
          <Text as="div" size="medium" color="brand" weight="bold" wrap="break-word">
            <IconAddSolid color="brand" title="Add Status" />
            <View as="span" margin="0 0 0 x-small" display="inline-block">
              {I18n.t('Add Status')}
            </View>
          </Text>
        </View>
        <EditStatusPopover
          currentColor={colorPickerColors[0].hexcode}
          isCustomStatus={true}
          isOpen={isEditOpen}
          handleEditSave={handleSave}
          handleEditStatusToggle={() => handleEditStatusToggle()}
          hideRenderTrigger={true}
          positionTarget={customStatusItemRef.current}
        />
      </GradingStatusListItem>
    </View>
  )
}
