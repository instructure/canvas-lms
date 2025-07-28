/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import tinycolor from 'tinycolor2'
import formatMessage from '../../../../format-message'
import {Button} from '@instructure/ui-buttons'
import {ColorPreset, ColorMixer, ColorContrast} from '@instructure/ui-color-picker'
import {Flex} from '@instructure/ui-flex'
import {Pill} from '@instructure/ui-pill'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Tabs} from '@instructure/ui-tabs'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {isTransparent, getContrastStatus, getDefaultColors} from './colorUtils'

export type ColorTab = 'foreground' | 'background' | 'border'

export type TabSpec = {
  color?: string
  default: string
}

export type ColorSpec = {
  bgcolor?: string
  fgcolor?: string
  bordercolor?: string
}

// A custom type constraint that enforces at least one key is present
export type AtLeastOne<T, U = {[K in keyof T]: Pick<T, K>}> = Partial<T> & U[keyof U]

export type TabsSpec = AtLeastOne<Record<ColorTab, TabSpec>> & {effectiveBgColor: string}

export type ColorsInUse = {
  foreground: string[]
  background: string[]
  border: string[]
}

export type ColorPickerProps = {
  tabs: TabsSpec
  colorsInUse?: ColorsInUse
  onCancel: () => void
  onSave: (newcolors: ColorSpec) => void
}

const ColorPicker = ({tabs, colorsInUse, onCancel, onSave}: ColorPickerProps) => {
  const [currFgColor, setCurrFgColor] = useState<string | undefined>(tabs.foreground?.color)
  const [currBgColor, setCurrBgColor] = useState<string | undefined>(
    isTransparent(tabs.background?.color)
      ? tabs.effectiveBgColor || '#ffffff'
      : tabs.background?.color,
  )
  const [currBorderColor, setCurrBorderColor] = useState(tabs.border?.color)
  const [activeTab, setActiveTab] = useState<ColorTab>(() => {
    if (tabs.foreground) return 'foreground'
    if (tabs.background) return 'background'
    return 'border'
  })
  const [defaultColors] = useState(getDefaultColors())
  const [customForeground, setCustomForeground] = useState<boolean>(
    !!tabs.foreground?.color && tabs.foreground.color !== tabs.foreground.default,
  )
  const [customBackground, setCustomBackground] = useState<boolean>(
    !isTransparent(tabs.background?.color) && tabs.background?.color !== tabs.background?.default,
  )
  const [customBorder, setCustomBorder] = useState<boolean>(
    !isTransparent(tabs.border?.color) && tabs.border?.color !== tabs.border?.default,
  )

  const handleFgColorChange = useCallback((newColor: string) => {
    setCurrFgColor(newColor)
  }, [])

  const handleBgColorChange = useCallback((newColor: string) => {
    const c = tinycolor(newColor).toHexString()
    setCurrBgColor(c)
  }, [])

  const handleBorderColorChange = useCallback((newColor: string) => {
    setCurrBorderColor(newColor)
  }, [])

  const handleTabChange = useCallback(
    (
      _event: React.MouseEvent<ViewOwnProps> | React.KeyboardEvent<ViewOwnProps>,
      tabData: {index: number; id?: string},
    ) => {
      setActiveTab(tabData.id as ColorTab)
    },
    [],
  )

  const handleChangePickAColor = useCallback(
    (_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
      const isCustom = value === 'custom'
      if (activeTab === 'foreground') {
        setCustomForeground(isCustom)
        if (!isCustom) {
          setCurrFgColor(undefined)
        }
      } else if (activeTab === 'background') {
        setCustomBackground(isCustom)
        if (!isCustom) {
          setCurrBgColor(undefined)
        }
      } else if (activeTab === 'border') {
        setCustomBorder(isCustom)
        if (!isCustom) {
          setCurrBorderColor('#00000000')
        }
      }
    },
    [activeTab],
  )

  const handleCancel = useCallback(() => {
    onCancel()
  }, [onCancel])

  const handleSubmit = useCallback(() => {
    setActiveTab(currFgColor ? 'foreground' : 'background')
    const newcolors: ColorSpec = {}

    if (customForeground && currFgColor) {
      const c = tinycolor(currFgColor).toHexString()
      newcolors.fgcolor = c
    }

    if (customBackground && currBgColor) {
      const c = tinycolor(currBgColor).toHexString()
      newcolors.bgcolor = c
    }

    if (currBorderColor) {
      newcolors.bordercolor =
        customBorder && !isTransparent(currBorderColor) ? currBorderColor : undefined
      if (newcolors.bordercolor) {
        const c = tinycolor(newcolors.bordercolor).toHexString()
        newcolors.bordercolor = c
      }
    }
    onSave(newcolors)
  }, [
    currBgColor,
    currBorderColor,
    currFgColor,
    customBackground,
    customBorder,
    customForeground,
    onSave,
  ])

  const getColorPresets = (variant: ColorTab) => {
    const defaults = defaultColors
    if (tabs.background?.default) {
      defaults[0] = tabs.background.default
    }
    if (tabs.foreground?.default) {
      defaults[1] = tabs.foreground.default
    }
    // return only unique colors
    return [...defaults, ...(colorsInUse?.[variant] || [])].filter(
      (c, i, a) => a.indexOf(c) === i && !isTransparent(c),
    )
  }

  const renderColorMixer = (variant: ColorTab, enabled: boolean) => {
    let value = currBgColor
    let onSelectColor = handleBgColorChange

    if (variant === 'foreground') {
      value = currFgColor as string
      onSelectColor = handleFgColorChange
    }
    if (variant === 'border') {
      value = currBorderColor as string
      onSelectColor = handleBorderColorChange
    }
    if (isTransparent(value)) value = '#fff' // or the ColorMixer will return a transparent color

    return (
      <ColorMixer
        data-testid="color-mixer"
        disabled={!enabled}
        value={value}
        withAlpha={false}
        onChange={onSelectColor}
        rgbRedInputScreenReaderLabel={formatMessage('Input field for red')}
        rgbGreenInputScreenReaderLabel={formatMessage('Input field for green')}
        rgbBlueInputScreenReaderLabel={formatMessage('Input field for blue')}
        rgbAlphaInputScreenReaderLabel={formatMessage('Input field for alpha')}
        colorSliderNavigationExplanationScreenReaderLabel={formatMessage(
          "You are on a color slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively",
        )}
        alphaSliderNavigationExplanationScreenReaderLabel={formatMessage(
          "You are on an alpha slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively",
        )}
        colorPaletteNavigationExplanationScreenReaderLabel={formatMessage(
          "You are on a color palette. To navigate on the palette up, left, down or right, use the 'W', 'A', 'S' and 'D' buttons respectively",
        )}
      />
    )
  }

  const renderColorPreset = (variant: ColorTab, enabled: boolean) => {
    let currColor = currBgColor
    if (variant === 'foreground') currColor = currFgColor || defaultColors[1]
    if (variant === 'border') currColor = currBorderColor || '#00000000'

    let onSelectColor = handleBgColorChange
    if (variant === 'foreground') onSelectColor = handleFgColorChange
    if (variant === 'border') onSelectColor = handleBorderColorChange

    return (
      <ColorPreset
        data-testid="color-preset"
        disabled={!enabled}
        label={formatMessage('Previously chosen colors')}
        colors={getColorPresets(variant)}
        selected={currColor}
        onSelect={onSelectColor}
      />
    )
  }

  // this will only get called if either tabs.foreground or tabs.border is defined
  const getFirstColor = (): {firstColor: string; firstColorLabel: string} => {
    let firstColor, firstColorLabel
    if (activeTab === 'foreground' || (activeTab === 'background' && !!tabs.foreground)) {
      firstColor = currFgColor || tabs.foreground?.default || defaultColors[0]
      firstColorLabel = formatMessage('Color')
    } else if (activeTab === 'border' || (activeTab === 'background' && !!tabs.border)) {
      firstColor = currBorderColor || tabs.border?.default || defaultColors[0]
      firstColorLabel = formatMessage('Border')
    }
    // @ts-expect-error
    return {firstColor, firstColorLabel}
  }

  const renderColorContrastSummary = () => {
    const {firstColor} = getFirstColor()
    const ok = getContrastStatus(firstColor, currBgColor || tabs.effectiveBgColor || '#fff')
    return (
      <Flex as="div" gap="x-large">
        <Text weight="bold">{formatMessage('Color Contrast')}</Text>
        <Pill color={ok ? 'success' : 'danger'}>
          {ok ? formatMessage('PASS') : formatMessage('FAIL')}
        </Pill>
      </Flex>
    )
  }

  const renderColorContrast = () => {
    if (!(tabs.background || tabs.effectiveBgColor)) return null
    if (!(tabs.foreground || tabs.border)) return null
    if (!currBgColor) return null

    const {firstColor, firstColorLabel} = getFirstColor()
    if (firstColor === null) return null

    return (
      <ToggleDetails summary={renderColorContrastSummary()} data-testid="color-contrast-summary">
        <View as="div" margin="small 0 0 0">
          <ColorContrast
            data-testid="color-contrast"
            firstColor={firstColor}
            secondColor={currBgColor || tabs.effectiveBgColor || '#fff'}
            label={formatMessage('Color Contrast Ratio')}
            successLabel={formatMessage('PASS')}
            failureLabel={formatMessage('FAIL')}
            normalTextLabel={formatMessage('Normal text')}
            largeTextLabel={formatMessage('Large text')}
            graphicsTextLabel={formatMessage('Graphics text')}
            firstColorLabel={firstColorLabel}
            secondColorLabel={formatMessage('Background')}
          />
        </View>
      </ToggleDetails>
    )
  }

  const renderTab = (variant: ColorTab) => {
    let choosersEnabled = true
    if (variant === 'foreground') {
      choosersEnabled = customForeground
    } else if (variant === 'background') {
      choosersEnabled = customBackground
    } else if (variant === 'border') {
      choosersEnabled = customBorder
    }

    return (
      <>
        <View as="div" margin="0 0 small 0">
          <RadioInputGroup
            layout="columns"
            name="pickcolor"
            description={formatMessage('Pick a color')}
            size="small"
            value={choosersEnabled ? 'custom' : 'none'}
            onChange={handleChangePickAColor}
          >
            <RadioInput label={formatMessage('Default')} value="none" />
            <RadioInput label={formatMessage('Custom')} value="custom" />
          </RadioInputGroup>
        </View>

        {renderColorMixer(variant, choosersEnabled)}
        {renderColorPreset(variant, choosersEnabled)}
      </>
    )
  }

  return (
    <View as="div" data-testid="color-picker">
      <View as="div" padding="small" data-mce-component={true}>
        <Tabs onRequestTabChange={handleTabChange}>
          {!!tabs.foreground && (
            <Tabs.Panel
              id="foreground"
              renderTitle={formatMessage('Color')}
              isSelected={activeTab === 'foreground'}
            >
              {renderTab('foreground')}
            </Tabs.Panel>
          )}
          {!!tabs.background && (
            <Tabs.Panel
              id="background"
              renderTitle={formatMessage('Background')}
              isSelected={activeTab === 'background'}
            >
              {renderTab('background')}
            </Tabs.Panel>
          )}
          {!!tabs.border && (
            <Tabs.Panel
              id="border"
              renderTitle={formatMessage('Border')}
              isSelected={activeTab === 'border'}
            >
              {renderTab('border')}
            </Tabs.Panel>
          )}
        </Tabs>
        {renderColorContrast()}
      </View>
      <View as="div" background="secondary" padding="small" textAlign="end">
        <Button onClick={handleCancel}>{formatMessage('Cancel')}</Button>
        <Button onClick={handleSubmit} margin="0 0 0 small" color="primary">
          {formatMessage('Apply')}
        </Button>
      </View>
    </View>
  )
}

export {ColorPicker}
