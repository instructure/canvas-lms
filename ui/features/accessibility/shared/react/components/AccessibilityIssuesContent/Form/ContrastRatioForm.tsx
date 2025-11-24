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

import React, {useState, useRef, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {ColorPicker, ColorContrast} from '@instructure/ui-color-picker'
import {FormMessage} from '@instructure/ui-form-field'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

interface ContrastRatioFormProps {
  label: string
  inputLabel: string
  options?: string[]
  messages?: FormMessage[]
  backgroundColor?: string
  foregroundColor?: string
  description?: string
  onChange: (value: string, isValid: boolean) => void
  inputRef?: (inputElement: HTMLInputElement | null) => void
}

const SUGGESTION_MESSAGE = I18n.t(
  "Tip: Only #0000 will automatically update to white if the user's background is in dark mode.",
)
const SUGGESTED_COLORS = ['#000000', '#248029', '#9242B4', '#2063C1', '#B50000']

const ContrastRatioForm: React.FC<ContrastRatioFormProps> = ({
  label,
  backgroundColor = '#FFFFFF',
  foregroundColor = '#000000',
  onChange,
  inputLabel,
  description,
  options = [],
  messages = [],
  inputRef,
}: ContrastRatioFormProps) => {
  const [selectedColor, setSelectedColor] = useState(foregroundColor)
  const pickerRef = useRef<HTMLDivElement | null>(null)
  const contrastForm = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    setSelectedColor(foregroundColor)
  }, [foregroundColor])

  useEffect(() => {
    if (pickerRef.current) {
      const buttonDiv = pickerRef.current.lastElementChild as HTMLElement
      if (buttonDiv) {
        buttonDiv.style.marginTop = 'auto'
      }
    }
  }, [])

  useEffect(() => {
    const wrapper = contrastForm.current as HTMLDivElement | null
    if (!wrapper) return

    const topLevelDivs = Array.from(wrapper.children).filter(
      el => el.tagName.toUpperCase() === 'DIV',
    )
    const statusWrappers = topLevelDivs.filter(div => div.textContent?.match(/(pass|fail|AAA|AA)/i))
    if (statusWrappers.length === 0) return
    const optionIndexMap: Record<string, number> = {
      normal: 0,
      large: 1,
      graphics: 2,
    }
    Object.entries(optionIndexMap).forEach(([key, index]) => {
      const el = statusWrappers[index] as HTMLElement
      if (!el) return

      if (options.includes(key)) {
        el.style.fontWeight = '700'
        const pillWrapper = el.children[1]
        const pill = pillWrapper.querySelector('span div > div') as HTMLElement // fallback if pill is inside a span
        if (pill) {
          pill.style.fontWeight = '700'
        }
      } else {
        el.style.display = 'none'
      }
    })
  }, [options])

  const calculateValidity = (contrastData: {
    contrast: number
    isValidNormalText: boolean
    isValidLargeText: boolean
    isValidGraphicsText: boolean
    firstColor: string
    secondColor: string
  }) => {
    let valid = true
    for (const option of options) {
      if (option === 'normal' && !contrastData.isValidNormalText) {
        valid = false
        break
      }
      if (option === 'large' && !contrastData.isValidLargeText) {
        valid = false
        break
      }
    }
    return valid
  }

  const handleContrastChange = (contrastData: {
    contrast: number
    isValidNormalText: boolean
    isValidLargeText: boolean
    isValidGraphicsText: boolean
    firstColor: string
    secondColor: string
  }) => {
    const valid = calculateValidity(contrastData)
    onChange(contrastData.secondColor, valid)
    // inst-ui function signature requires returning null
    return null
  }

  const handleColorChange = (newColor: string) => {
    setSelectedColor(newColor)
  }

  return (
    <View as="div" data-testid="contrast-ratio-form">
      <ColorContrast
        firstColor={backgroundColor}
        secondColor={selectedColor}
        label={label}
        successLabel={I18n.t('PASS')}
        failureLabel={I18n.t('FAIL')}
        normalTextLabel={I18n.t('NORMAL TEXT')}
        largeTextLabel={I18n.t('LARGE TEXT')}
        graphicsTextLabel={I18n.t('GRAPHICS TEXT')}
        firstColorLabel={I18n.t('Background')}
        secondColorLabel={I18n.t('Foreground')}
        onContrastChange={handleContrastChange}
        elementRef={r => {
          if (r instanceof HTMLDivElement || r === null) {
            contrastForm.current = r
          }
        }}
      />
      <View as="section" margin="medium 0 large 0">
        <View as="div" margin="x-small 0">
          <Heading level="h4" variant="titleCardMini">
            {I18n.t('Issue description')}
          </Heading>
        </View>
        <Text weight="weightRegular">{description}</Text>
      </View>
      <View as="div" margin="medium 0" style={{overflow: 'visible'}}>
        <ColorPicker
          id="a11y-color-picker"
          data-testid="color-picker"
          placeholderText={I18n.t('Enter HEX')}
          label={inputLabel}
          elementRef={r => {
            if (r instanceof HTMLDivElement || r === null) {
              pickerRef.current = r
            }
          }}
          value={selectedColor}
          onChange={handleColorChange}
          inputRef={inputRef}
          renderMessages={() => messages}
          colorMixerSettings={{
            popoverAddButtonLabel: I18n.t('Select'),
            popoverCloseButtonLabel: I18n.t('Close'),
            colorMixer: {
              rgbRedInputScreenReaderLabel: I18n.t('Input field for red'),
              rgbGreenInputScreenReaderLabel: I18n.t('Input field for green'),
              rgbBlueInputScreenReaderLabel: I18n.t('Input field for blue'),
              rgbAlphaInputScreenReaderLabel: I18n.t('Input field for alpha'),
              colorSliderNavigationExplanationScreenReaderLabel: I18n.t(
                'Use left and right arrows to adjust color.',
              ),
              alphaSliderNavigationExplanationScreenReaderLabel: I18n.t(
                'Use left and right arrows to adjust alpha.',
              ),
              colorPaletteNavigationExplanationScreenReaderLabel: I18n.t(
                'Use arrow keys to navigate the color palette.',
              ),
              withAlpha: false,
            },
            colorPreset: {
              label: I18n.t('Suggested colors'),
              colors: SUGGESTED_COLORS,
            },
            colorContrast: {
              label: I18n.t('Contrast Ratio'),
              firstColorLabel: I18n.t('Background'),
              secondColorLabel: I18n.t('Foreground'),
              normalTextLabel: I18n.t('NORMAL TEXT'),
              largeTextLabel: I18n.t('LARGE TEXT'),
              graphicsTextLabel: I18n.t('GRAPHICS TEXT'),
              successLabel: I18n.t('PASS'),
              failureLabel: I18n.t('FAIL'),
              firstColor: backgroundColor,
            },
          }}
          popoverButtonScreenReaderLabel={I18n.t('New text color picker')}
        />
      </View>
      {backgroundColor.toUpperCase() === '#FFFFFF' && (
        <Text data-testid="suggestion-message">{SUGGESTION_MESSAGE}</Text>
      )}
    </View>
  )
}

export default ContrastRatioForm
