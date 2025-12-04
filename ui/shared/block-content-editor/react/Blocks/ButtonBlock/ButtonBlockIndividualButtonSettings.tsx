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

import {useState, useCallback, useRef, useEffect} from 'react'
import {Flex} from '@instructure/ui-flex'
import {IconButton, Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {IconTrashLine, IconAddLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TruncateText} from '@instructure/ui-truncate-text'
import './individual-button-settings.css'
import {ButtonBlockIndividualButtonSettingsProps} from './types'
import {ButtonData, ButtonStyle} from '../BlockItems/Button/types'
import {useButtonManager} from './useButtonManager'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {Heading} from '@instructure/ui-heading'

const I18n = createI18nScope('block_content_editor')

export const ButtonBlockIndividualButtonSettings = ({
  backgroundColor,
  initialButtons,
  onButtonsChange,
}: ButtonBlockIndividualButtonSettingsProps) => {
  const [expandedButtonId, setExpandedButtonId] = useState<number | null>(null)
  const [focusButtonId, setFocusButtonId] = useState<number | null>(null)
  const toggleRefs = useRef<Record<number, ToggleGroup | null>>({})
  const {buttons, addButton, removeButton, updateButton, canAddButton, canDeleteButton} =
    useButtonManager(initialButtons, onButtonsChange)

  useEffect(() => {
    if (focusButtonId) {
      const toggleRef = toggleRefs.current[focusButtonId]
      toggleRef?.focus()
      setFocusButtonId(null)
    }
  }, [focusButtonId, buttons])

  const handleButtonToggle = useCallback((buttonId: number) => {
    setExpandedButtonId(prevId => (prevId === buttonId ? null : buttonId))
  }, [])

  const handleButtonRemove = useCallback(
    (buttonId: number, buttonIndex: number) => {
      if (buttons.length <= 1) return

      const buttonAboveIndex = buttonIndex - 1
      const buttonToFocus = buttonAboveIndex >= 0 ? buttons[buttonAboveIndex] : buttons[1]

      removeButton(buttonId)
      setExpandedButtonId(prevId => (prevId === buttonId ? null : prevId))
      delete toggleRefs.current[buttonId]

      if (buttonToFocus) {
        setFocusButtonId(buttonToFocus.id)
      }
    },
    [removeButton, buttons],
  )

  const renderButtonSettingsContent = (button: ButtonData) => (
    <Flex direction="column" gap="small">
      <TextInput
        renderLabel={I18n.t('Button text')}
        value={button.text}
        onChange={(_e, value) => updateButton(button.id, {text: value})}
        placeholder={I18n.t('Button')}
      />
      <SimpleSelect
        renderLabel={I18n.t('Button style')}
        value={button.style}
        onChange={(_e, option) => updateButton(button.id, {style: option.value as ButtonStyle})}
        data-testid="select-button-style-dropdown"
      >
        <SimpleSelect.Option id="filled" key="filled" value="filled">
          {I18n.t('Filled')}
        </SimpleSelect.Option>
        <SimpleSelect.Option id="outlined" key="outlined" value="outlined">
          {I18n.t('Outlined')}
        </SimpleSelect.Option>
      </SimpleSelect>
      <ColorPickerWrapper
        label={I18n.t('Button color')}
        popoverButtonScreenReaderLabel={I18n.t('Open button color picker popover')}
        value={button.primaryColor}
        baseColor={button.style === 'filled' ? button.secondaryColor : backgroundColor}
        baseColorLabel={
          button.style === 'filled' ? I18n.t('Text color') : I18n.t('Background color')
        }
        onChange={color => updateButton(button.id, {primaryColor: color})}
      />
      {button.style === 'filled' && (
        <ColorPickerWrapper
          label={I18n.t('Text color')}
          popoverButtonScreenReaderLabel={I18n.t('Open text color picker popover')}
          value={button.secondaryColor}
          baseColor={button.primaryColor}
          baseColorLabel={I18n.t('Background color')}
          onChange={color => updateButton(button.id, {secondaryColor: color})}
        />
      )}
      <TextInput
        renderLabel={I18n.t('URL')}
        value={button.url}
        onChange={(_e, value) => updateButton(button.id, {url: value})}
        placeholder={I18n.t('URL')}
      />
      <SimpleSelect
        value={button.linkOpenMode}
        renderLabel={I18n.t('How to open link')}
        onChange={(_e: any, {value}: any) => updateButton(button.id, {linkOpenMode: value})}
        data-testid="select-content-type-dropdown"
      >
        <SimpleSelect.Option key="new-tab" id="new-tab" value="new-tab">
          {I18n.t('Open in a new tab')}
        </SimpleSelect.Option>
        <SimpleSelect.Option key="same-tab" id="same-tab" value="same-tab">
          {I18n.t('Open in the current tab')}
        </SimpleSelect.Option>
      </SimpleSelect>
    </Flex>
  )

  const renderButtonSettings = (button: ButtonData, buttonIndex: number) => {
    const isExpanded = expandedButtonId === button.id
    const buttonTitle = button.text || I18n.t('Button')
    return (
      <View
        key={button.id}
        background={isExpanded ? 'secondary' : 'primary'}
        borderColor="primary"
        borderRadius="medium"
        borderWidth="small"
      >
        <ToggleGroup
          summary={
            <Flex justifyItems="space-between" alignItems="center">
              <Flex.Item shouldGrow shouldShrink>
                <Heading level="h4">
                  <TruncateText>{buttonTitle}</TruncateText>
                </Heading>
              </Flex.Item>
              <IconButton
                onClick={() => handleButtonRemove(button.id, buttonIndex)}
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Delete %{buttonTitle}', {
                  buttonTitle: buttonTitle,
                })}
                disabled={!canDeleteButton}
                margin="0 medium"
                data-testid={`button-settings-delete-${button.id}`}
              >
                <IconTrashLine />
              </IconButton>
            </Flex>
          }
          expanded={isExpanded}
          onToggle={() => handleButtonToggle(button.id)}
          toggleLabel={I18n.t('%{buttonTitle} settings', {buttonTitle})}
          data-buttonsettingstoggle
          data-testid={`button-settings-toggle-${button.id}`}
          ref={(el: ToggleGroup | null) => {
            toggleRefs.current[button.id] = el
          }}
        >
          <View as="div" padding="small" data-testid={`button-settings-${button.id}`}>
            {renderButtonSettingsContent(button)}
          </View>
        </ToggleGroup>
      </View>
    )
  }

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
