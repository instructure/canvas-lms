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
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ColorPicker} from '@instructure/ui-color-picker'
import {Pill} from '@instructure/ui-pill'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ContrastData} from '../../../types'

const I18n = createI18nScope('accessibility_checker')

interface ContrastRatioFormProps {
  label: string
  inputLabel: string
  options?: string[]
  backgroundColor?: string
  foregroundColor?: string
  contrastRatio?: number
  onChange: (value: string) => void
}

const optionMap: Record<string, keyof ContrastData> = {
  normal: 'isValidNormalText',
  large: 'isValidLargeText',
  graphics: 'isValidGraphicsText',
}

const SUGGESTED_COLORS = ['#000000', '#248029', '#9242B4', '#2063C1', '#B50000']

const Swatch = ({
  label,
  color,
}: {
  label: string
  color: string
}) => (
  <Flex alignItems="center" gap="x-small">
    <View
      width="1.5rem"
      height="1.5rem"
      borderRadius="circle"
      borderWidth="small"
      background="primary"
      themeOverride={{backgroundPrimary: color}}
      aria-label={`${label}: ${color}`}
    />
    <View as="div">
      <Text as="div" size="small">
        {label}
      </Text>
      <Text as="div" size="small" color="secondary">
        {color}
      </Text>
    </View>
  </Flex>
)

const ContrastOptions = ({
  options,
  isOptionsValid,
  badgeColor,
}: {
  options: string[]
  isOptionsValid: (option: string) => boolean
  badgeColor: 'success' | 'danger'
}) => (
  <View as="div" margin="x-small 0 medium 0">
    {options.map((option, index) => (
      <Flex key={index} margin="0" justifyItems="space-between" width="272px">
        <Text
          color={isOptionsValid(option) ? 'success' : 'danger'}
          themeOverride={{dangerColor: '#E62429'}}
          size="small"
          weight="bold"
        >
          {I18n.t(`%{option} TEXT`, {option: option.toUpperCase()})}
        </Text>
        <Pill color={badgeColor} margin="xx-small">
          {isOptionsValid(option) ? I18n.t('PASS') : I18n.t('FAIL')}
        </Pill>
      </Flex>
    ))}
  </View>
)

const ContrastRatioForm: React.FC<ContrastRatioFormProps> = ({
  label,
  backgroundColor = '#FFFFFF',
  foregroundColor = '#000000',
  contrastRatio = 1,
  onChange,
  inputLabel,
  options = [],
}: ContrastRatioFormProps) => {
  const [selectedColor, setSelectedColor] = useState(foregroundColor)
  const [tempContrastData, setTempContrastData] = useState<ContrastData | null>(null)
  const [contrastData, setContrastData] = useState<ContrastData | null>(null)
  const pickerRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    setSelectedColor(foregroundColor)
    setContrastData(null)
  }, [foregroundColor])

  useEffect(() => {
    if (pickerRef.current) {
      const buttonDiv = pickerRef.current.lastElementChild as HTMLElement
      if (buttonDiv) {
        buttonDiv.style.marginTop = 'auto'
      }
    }
  }, [])

  const badgeColor = contrastData?.isValidNormalText ? 'success' : 'danger'

  const isOptionsValid = (option: string): boolean => {
    const key = optionMap[option]
    return !!(key && contrastData && contrastData[key])
  }

  const handleColorChange = (newColor: string) => {
    setSelectedColor(newColor)
    onChange(newColor)
    if (tempContrastData) {
      setContrastData(tempContrastData)
    }
  }

  return (
    <View as="div" margin="0 0 large 0" data-testid="contrast-ratio-form">
      <Text weight="bold" size="medium">
        {label}
      </Text>
      <Text as="div" size="x-large" color="primary">
        {`${contrastData?.contrast || contrastRatio?.toFixed(2)}:1`}
      </Text>

      <Flex margin="x-small 0 medium 0" justifyItems="space-between" width="272px">
        <Swatch label="Background" color={backgroundColor} />
        <Swatch label="Foreground" color={selectedColor} />
      </Flex>
      <ContrastOptions options={options} isOptionsValid={isOptionsValid} badgeColor={badgeColor} />
      <View margin="medium 0">
        <ColorPicker
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
              onContrastChange: (data: ContrastData) => {
                setTempContrastData(data)
                return null
              },
            },
          }}
        />
      </View>
    </View>
  )
}

export default ContrastRatioForm
