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

import React, {useEffect, useState} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Color} from '@canvas/grading-status-list-item'
import '@canvas/rails-flash-notifications'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconWarningSolid, IconCheckSolid} from '@instructure/ui-icons'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('calendar_color_picker')

const COLORS_PER_ROW = 5
const DEFAULT_COLOR_PREVIEW = '#FFFFFF'

const checkIfValidHex = (color: string, allowWhite: boolean) => {
  if (!allowWhite) {
    // prevent selection of white (#fff or #ffffff)
    const whiteHexRe = /^#?([fF]{3}|[fF]{6})$/
    if (whiteHexRe.test(color)) {
      return false
    }
  }

  // ensure hex is valid
  const validHexRe = /^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
  return validHexRe.test(color)
}

const getHexValue = (color: string) => {
  return color[0] === '#' ? color : `#${color}`
}

type ColorPickerProps = {
  colors: Color[]
  colorLabels: Record<string, string>
  defaultColor: string
  allowWhite: boolean
  setStatusColor: (color: string) => void
  setIsValidColor: (isValid: boolean) => void
}

export const ColorPicker = ({
  colors,
  colorLabels,
  defaultColor,
  allowWhite,
  setStatusColor,
  setIsValidColor,
}: ColorPickerProps) => {
  const [currentColor, setCurrentColor] = useState(defaultColor)
  const [isValidHex, setIsValidHex] = useState(checkIfValidHex(defaultColor, allowWhite))

  useEffect(() => {
    const isValid = checkIfValidHex(currentColor, allowWhite)
    setIsValidHex(isValid)

    setStatusColor(currentColor)
    setIsValidColor(isValid)
  }, [allowWhite, currentColor, setIsValidColor, setStatusColor])

  const warnIfInvalid = () => {
    if (!isValidHex) {
      showFlashAlert({
        message: I18n.t(
          "'%{chosenColor}' is not a valid color. Enter a valid hexcode before saving.",
          {
            chosenColor: currentColor,
          }
        ),
        type: 'warning',
        srOnly: true,
      })
    }
  }

  const setInputColor = (event: any) => {
    const value = getHexValue(event.target.value)
    setCurrentColor(value)
  }

  const renderColorRows = () => {
    const colorRows = []

    for (let i = 0; i < colors.length; i += COLORS_PER_ROW) {
      colorRows.push(
        <ColorRow
          key={`color-row-${i}`}
          colors={colors.slice(i, i + COLORS_PER_ROW)}
          colorLabels={colorLabels}
          currentColor={currentColor}
          handleOnClick={setCurrentColor}
        />
      )
    }

    return colorRows
  }

  return (
    <View as="div" data-testid="color-picker">
      {renderColorRows()}

      <Flex wrap="wrap" justifyItems="space-between" margin="small 0 0 0">
        <Flex.Item margin="0 x-small 0 0">
          <ColorPreview currentColor={currentColor} isValidHex={isValidHex} />
        </Flex.Item>
        <Flex.Item margin="0 0 0 x-small">
          <View as="span">
            <TextInput
              renderLabel={
                <ScreenReaderContent>
                  {isValidHex
                    ? I18n.t('Enter a hexcode here to use a custom color.')
                    : I18n.t('Invalid hexcode. Enter a valid hexcode here to use a custom color.')}
                </ScreenReaderContent>
              }
              value={currentColor}
              onChange={setInputColor}
              onBlur={warnIfInvalid}
              data-testid="color-picker-input"
            />
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

type ColorPreviewProps = {
  currentColor: string
  isValidHex: boolean
}
const ColorPreview = ({currentColor, isValidHex}: ColorPreviewProps) => {
  const previewColor = getHexValue(isValidHex ? currentColor : DEFAULT_COLOR_PREVIEW)

  return (
    <ColorTile hexcode={previewColor} isFocusable={false}>
      {!isValidHex && (
        <Tooltip renderTip={I18n.t('Invalid hexcode')}>
          <IconWarningSolid color="warning" id="ColorPicker__InvalidHex" />
        </Tooltip>
      )}
    </ColorTile>
  )
}

type ColorRowsProps = {
  colors: Color[]
  colorLabels: Record<string, string>
  currentColor: string
  handleOnClick: (hexcode: string) => void
}
const ColorRow = ({colors, colorLabels, currentColor, handleOnClick}: ColorRowsProps) => {
  return (
    <Flex wrap="wrap" justifyItems="space-between" margin="small 0 0 0">
      {colors.map(color => {
        const {hexcode, name: colorName} = color
        const isSelected = currentColor === hexcode
        const colorLabel = colorLabels[colorName]
        return (
          <Flex.Item key={colorName}>
            <ColorTile
              isSelected={isSelected}
              hexcode={hexcode}
              handleOnClick={() => handleOnClick(hexcode)}
            >
              <ScreenReaderContent>
                {I18n.t('Color Option %{colorLabel}, hex code: %{hexcode}', {colorLabel, hexcode})}
              </ScreenReaderContent>
              {isSelected && (
                <>
                  <ScreenReaderContent>{I18n.t('Currently Selected Color')}</ScreenReaderContent>
                  <IconCheckSolid />
                </>
              )}
            </ColorTile>
          </Flex.Item>
        )
      })}
    </Flex>
  )
}

type ColorTileProps = {
  hexcode: string
  children: React.ReactNode
  isFocusable?: boolean
  isSelected?: boolean
  handleOnClick?: () => void
}
const ColorTile = ({
  hexcode,
  isFocusable = true,
  isSelected,
  children,
  handleOnClick,
}: ColorTileProps) => {
  return (
    <View
      as="button"
      position="relative"
      className="ColorPicker__ColorPreview"
      width="2.1rem"
      height="2.1rem"
      cursor="pointer"
      background="primary"
      borderWidth={isSelected ? 'medium' : 'small'}
      tabIndex={isFocusable ? 0 : -1}
      borderColor="primary"
      data-testid={`color-picker-${hexcode}`}
      themeOverride={{backgroundPrimary: hexcode, borderColorPrimary: '#000000'}}
      onClick={handleOnClick}
    >
      {children}
    </View>
  )
}
