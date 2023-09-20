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

import React, {useState} from 'react'
import {colorPickerColors, defaultColorLabels} from '@canvas/grading-status-list-item'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, IconButton} from '@instructure/ui-buttons'
// @ts-expect-error
import {IconEditSolid} from '@instructure/ui-icons'
// @ts-expect-error
import {Popover} from '@instructure/ui-popover'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {ColorPicker} from './ColorPicker'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('account_grading_status')

const {Item: FlexItem} = Flex as any

type EditStatusPopoverProps = {
  currentColor: string
  customStatusName?: string
  editButtonLabel?: string
  hideRenderTrigger?: boolean
  isOpen: boolean
  isCustomStatus?: boolean
  positionTarget?: HTMLElement | null
  handleEditSave: (color: string, name: string) => void
  handleEditStatusToggle: () => void
}
export const EditStatusPopover = ({
  currentColor,
  customStatusName,
  editButtonLabel,
  isCustomStatus,
  isOpen,
  positionTarget,
  hideRenderTrigger,
  handleEditSave,
  handleEditStatusToggle,
}: EditStatusPopoverProps) => {
  const [selectedColor, setSelectedColor] = useState(currentColor)
  const [isSelectedColorValid, setIsSelectedColorValid] = useState(true)
  const [updatedCustomStatusName, setUpdatedCustomStatusName] = useState(customStatusName)

  return (
    <Popover
      on="click"
      isShowingContent={isOpen}
      shouldReturnFocus={true}
      positionTarget={positionTarget}
      renderTrigger={
        !hideRenderTrigger && (
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Open Edit Status Dialog for %{editButtonLabel}', {
              editButtonLabel,
            })}
            onClick={handleEditStatusToggle}
          >
            <IconEditSolid />
          </IconButton>
        )
      }
    >
      <View padding="0 medium" display="block" data-testid="edit-status-popover">
        {isCustomStatus && (
          <View as="div" margin="small 0 0 0">
            <TextInput
              data-testid="custom-status-name-input"
              renderLabel={I18n.t('Custom Status Name')}
              value={updatedCustomStatusName ?? ''}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => {
                setUpdatedCustomStatusName(e.target.value.substring(0, 14))
              }}
            />
          </View>
        )}
        <View as="div" margin="small 0 0 0">
          <Text size="medium" weight="bold">
            {I18n.t('Status Color')}
          </Text>
        </View>
        <ColorPicker
          allowWhite={true}
          colors={colorPickerColors}
          colorLabels={defaultColorLabels}
          defaultColor={currentColor}
          setStatusColor={setSelectedColor}
          setIsValidColor={setIsSelectedColorValid}
        />
        <Flex direction="row-reverse" margin="small 0">
          <FlexItem>
            <Button
              color="secondary"
              onClick={() => {
                handleEditStatusToggle()
                setUpdatedCustomStatusName(customStatusName)
              }}
            >
              {I18n.t('Cancel')}
            </Button>
            <Button
              data-testid="save-status-button"
              color="primary"
              margin="0 0 0 small"
              disabled={!isSelectedColorValid || (isCustomStatus && !updatedCustomStatusName)}
              onClick={() => {
                handleEditSave(selectedColor, updatedCustomStatusName ?? '')
              }}
            >
              {I18n.t('Save')}
            </Button>
          </FlexItem>
        </Flex>
      </View>
    </Popover>
  )
}
