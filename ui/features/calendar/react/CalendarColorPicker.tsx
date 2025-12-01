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
import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {PREDEFINED_COLORS} from '@canvas/color-picker'
import {TextInput} from '@instructure/ui-text-input'
import {ColorIndicator, ColorPreset} from '@instructure/ui-color-picker'
import {Modal} from '@instructure/ui-modal'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {IconWarningSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {showFlashError, showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Button} from '@instructure/ui-buttons'
import forceScreenreaderToReparse from 'force-screenreader-to-reparse'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {set} from 'es-toolkit/compat'

const I18n = createI18nScope('calendar_sidebar')

const INITIAL_INPUT_COLOR = '#efefef'

const isValidHex = (color: string) => {
  const whiteHexRe = /^#?([fF]{3}|[fF]{6})$/
  if (whiteHexRe.test(color)) {
    return false
  }
  const validHexRe = /^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
  return validHexRe.test(color)
}

type CalendarColorPickerProps = {
  assetString: string
}

export const CalendarColorPicker: React.FC<CalendarColorPickerProps> = ({assetString}) => {
  const [isOpen, setIsOpen] = useState(true)
  const [currentColor, setCurrentColor] = useState<string>('#efefef')
  const [saveInProgress, setSaveInProgress] = useState(false)

  const onApply = async () => {
    if (!isValidHex(currentColor)) {
      showFlashAlert({
        message: I18n.t("'%{chosenColor}' is not a valid color.", {
          chosenColor: currentColor,
        }),
        type: 'warning',
      })
      return
    }

    if (currentColor.toLowerCase() === INITIAL_INPUT_COLOR) {
      setIsOpen(false)
      return
    }

    setSaveInProgress(true)
    try {
      const formData = new FormData()
      formData.append('hexcode', currentColor.replace('#', ''))

      await doFetchApi({
        path: `/api/v1/users/${window.ENV.current_user_id}/colors/${assetString}`,
        method: 'PUT',
        body: formData,
      })

      const styleOverrides = document.getElementById('calendar_color_style_overrides')
      if (styleOverrides) {
        const style = document.createElement('style')
        style.textContent = `
          .group_${assetString},
          .group_${assetString}:hover,
          .group_${assetString}:focus {
            color: ${currentColor};
            border-color: ${currentColor};
            background-color: ${currentColor};
          }
      `
        styleOverrides.appendChild(style)
      }

      setIsOpen(false)
      const appEl = document.getElementById('application')
      if (appEl) forceScreenreaderToReparse(appEl)
    } catch (err) {
      console.error('Failed to save color:', err)
      showFlashError(I18n.t("Could not save '%{chosenColor}'", {chosenColor: currentColor}))()
    } finally {
      setSaveInProgress(false)
    }
  }

  return (
    <Modal
      as="form"
      open={isOpen}
      label={I18n.t('Calendar Color Picker')}
      onDismiss={() => setIsOpen(false)}
      size="auto"
      data-testid="calendar-color-picker-modal"
      shouldCloseOnDocumentClick
      mountNode={() => document.getElementById('calendars_color_picker_holder')}
    >
      <Flex
        padding="small"
        direction="column"
        gap="small"
        data-testid="color-picker-color-container"
      >
        <ColorPreset
          label={I18n.t('Select course colour')}
          colors={PREDEFINED_COLORS.map(c => c.hexcode)}
          onSelect={setCurrentColor}
          selected={currentColor}
        />
        <TextInput
          value={currentColor}
          renderLabel={
            <ScreenReaderContent>
              {I18n.t('Enter a hexcode here to use a custom color.')}
            </ScreenReaderContent>
          }
          id={`ColorPickerCustomInput-${assetString}`}
          renderBeforeInput={<ColorIndicator color={currentColor} />}
          onChange={e => setCurrentColor(e.target.value)}
          data-testid="color-picker-input"
          messages={
            isValidHex(currentColor)
              ? []
              : [
                  {
                    type: 'error',
                    text: (
                      <View textAlign="center">
                        <View as="div" display="inline-block" margin="0 xxx-small xx-small 0">
                          <IconWarningSolid />
                        </View>
                        {I18n.t('Invalid format')}
                      </View>
                    ),
                  },
                ]
          }
        />
        <Flex justifyItems="end" gap="small" margin="xx-small 0 0 0">
          <Button data-testid="ColorPicker__Cancel" onClick={() => setIsOpen(false)}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            data-testid="ColorPicker__Apply"
            disabled={saveInProgress}
            onClick={onApply}
          >
            {I18n.t('Apply')}
          </Button>
        </Flex>
      </Flex>
    </Modal>
  )
}
