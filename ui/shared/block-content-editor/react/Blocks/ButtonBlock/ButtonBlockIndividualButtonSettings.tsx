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

import {useEffect, useState, useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {IconButton, Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconTrashLine, IconAddLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import './individual-button-settings.css'
import {ButtonData, ButtonBlockIndividualButtonSettingsProps} from './types'
import {useButtonManager} from './useButtonManager'
import {ToggleGroup} from '@instructure/ui-toggle-details'

const I18n = createI18nScope('block_content_editor')

export const ButtonBlockIndividualButtonSettings = ({
  initialButtons,
  onButtonsChange,
}: ButtonBlockIndividualButtonSettingsProps) => {
  const [expandedButtonId, setExpandedButtonId] = useState<number | null>(null)
  const {buttons, addButton, removeButton, updateButton, canAddButton, canDeleteButton} =
    useButtonManager(initialButtons, onButtonsChange)

  const handleButtonToggle = useCallback((buttonId: number) => {
    setExpandedButtonId(prevId => (prevId === buttonId ? null : buttonId))
  }, [])

  const handleButtonRemove = useCallback(
    (buttonId: number) => {
      removeButton(buttonId)
      setExpandedButtonId(prevId => (prevId === buttonId ? null : prevId))
    },
    [removeButton],
  )

  const renderButtonSettingsContent = (button: ButtonData) => (
    <Flex direction="column" gap="small">
      <TextInput
        renderLabel={I18n.t('Button text')}
        value={button.text}
        onChange={(_e, value) => updateButton(button.id, {text: value})}
        placeholder={I18n.t('Button')}
      />
    </Flex>
  )

  const renderButtonSettings = (button: ButtonData) => (
    <View
      key={button.id}
      background={expandedButtonId === button.id ? 'secondary' : 'primary'}
      borderColor="primary"
      borderRadius="medium"
      borderWidth="small"
    >
      <ToggleGroup
        summary={
          <Flex justifyItems="space-between" alignItems="center">
            <Text>{I18n.t('Button')}</Text>
            <IconButton
              onClick={() => handleButtonRemove(button.id)}
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t('Delete button')}
              disabled={!canDeleteButton}
              margin="0 medium"
              data-testid={`button-settings-delete-${button.id}`}
            >
              <IconTrashLine />
            </IconButton>
          </Flex>
        }
        expanded={expandedButtonId === button.id}
        onToggle={() => handleButtonToggle(button.id)}
        toggleLabel={
          expandedButtonId === button.id
            ? I18n.t('Collapse button settings')
            : I18n.t('Expand button settings')
        }
        data-buttonsettingstoggle
        data-testid={`button-settings-toggle-${button.id}`}
      >
        <View as="div" padding="small" data-testid={`button-settings-${button.id}`}>
          {renderButtonSettingsContent(button)}
        </View>
      </ToggleGroup>
    </View>
  )

  return (
    <View as="div" className="individual-button-settings-container">
      <Flex direction="column" gap="small">
        <Text variant="contentSmall">
          {I18n.t('You can add between 1 and 5 buttons in a block.')}
        </Text>

        {buttons.map(renderButtonSettings)}

        <Button onClick={addButton} renderIcon={<IconAddLine />} disabled={!canAddButton}>
          {I18n.t('New button')}
        </Button>
      </Flex>
    </View>
  )
}
