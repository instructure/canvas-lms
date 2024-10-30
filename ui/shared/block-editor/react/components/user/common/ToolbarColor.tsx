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

import React, {useCallback, useEffect, useState} from 'react'
import {Button, IconButton} from '@instructure/ui-buttons'
import {ColorPreset, ColorMixer, ColorContrast} from '@instructure/ui-color-picker'
import {Popover} from '@instructure/ui-popover'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Tabs} from '@instructure/ui-tabs'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {IconBackgroundColor} from '../../../assets/internal-icons'
import {isTransparent} from '../../../utils'

import {useScope} from '@canvas/i18n'

const I18n = useScope('block-editor')

// this will hold colors the user picks during this session
const previouslyChosenColors: string[] = []

type ColorTab = 'foreground' | 'background' | 'border'

export type ColorSpec = {
  bgcolor: string
  fgcolor?: string
  bordercolor?: string
}

export type ToolbarColorProps = {
  fgcolor?: string
  bgcolor: string
  bordercolor?: string
  onChange: (newcolors: ColorSpec) => void
}

const ToolbarColor = ({bgcolor, onChange, fgcolor, bordercolor}: ToolbarColorProps) => {
  const [currFgColor, setCurrFgColor] = useState(fgcolor)
  const [currBgColor, setCurrBgColor] = useState(bgcolor)
  const [currBorderColor, setCurrBorderColor] = useState(bordercolor || '#00000000')
  const [activeTab, setActiveTab] = useState<ColorTab>(fgcolor ? 'foreground' : 'background')
  const [customBackground, setCustomBackground] = useState<boolean>(false)
  const [customBorder, setCustomBorder] = useState<boolean>(false)
  const [isShowingContent, setIsShowingContent] = useState(false)
  const [recreateKey, setRecreateKey] = useState(0)
  const [defaultColors] = useState(() => {
    const fontcolor =
      window
        .getComputedStyle(document.documentElement)
        .getPropertyValue('--ic-brand-font-color-dark') || '#000000'
    return [fontcolor, '#FFFFFF']
  })

  useEffect(() => {
    if (!isShowingContent) {
      setRecreateKey(Date.now())
    }
  }, [isShowingContent])

  const updatePreviousColors = useCallback(
    (color: string) => {
      if (previouslyChosenColors.includes(color)) return
      if (defaultColors.includes(color)) return
      if (color === `${defaultColors[0]}FF`) return
      if (isTransparent(color)) return

      previouslyChosenColors.unshift(color)
      if (previouslyChosenColors.length > 8) previouslyChosenColors.pop()
    },
    [defaultColors]
  )

  const handleFgColorChange = useCallback((newColor: string) => {
    setCurrFgColor(newColor)
  }, [])

  const handleBgColorChange = useCallback((newColor: string) => {
    setCurrBgColor(newColor)
  }, [])

  const handleBorderColorChange = useCallback((newColor: string) => {
    setCurrBorderColor(newColor)
  }, [])

  const handleTabChange = useCallback(
    (
      _event: React.MouseEvent<ViewOwnProps> | React.KeyboardEvent<ViewOwnProps>,
      tabData: {index: number; id?: string}
    ) => {
      setActiveTab(tabData.id as ColorTab)
    },
    []
  )

  const handleShowContent = useCallback(() => {
    setIsShowingContent(true)
  }, [])

  const handleHideContent = useCallback(() => {
    setIsShowingContent(false)
    setActiveTab('foreground')
  }, [])

  const handleChangePickAColor = useCallback(
    (_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
      const isCustom = value === 'custom'
      if (activeTab === 'background') {
        setCustomBackground(isCustom)
        if (!isCustom) {
          setCurrBgColor('#00000000')
        }
      } else if (activeTab === 'border') {
        setCustomBorder(isCustom)
        if (!isCustom) {
          setCurrBorderColor('#00000000')
        }
      }
    },
    [activeTab]
  )

  const handleSubmit = useCallback(() => {
    setIsShowingContent(false)
    const newcolors: ColorSpec = {
      bgcolor: customBackground ? currBgColor : '#00000000',
    }
    updatePreviousColors(newcolors.bgcolor)

    if (currFgColor) {
      newcolors.fgcolor = currFgColor
      updatePreviousColors(currFgColor)
    }
    if (currBorderColor) {
      newcolors.bordercolor =
        customBorder && !isTransparent(currBorderColor) ? currBorderColor : undefined
      if (newcolors.bordercolor) {
        updatePreviousColors(newcolors.bordercolor)
      }
    }
    onChange(newcolors)
  }, [
    currBgColor,
    currBorderColor,
    currFgColor,
    customBackground,
    customBorder,
    onChange,
    updatePreviousColors,
  ])

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
        rgbRedInputScreenReaderLabel={I18n.t('Input field for red')}
        rgbGreenInputScreenReaderLabel={I18n.t('Input field for green')}
        rgbBlueInputScreenReaderLabel={I18n.t('Input field for blue')}
        rgbAlphaInputScreenReaderLabel={I18n.t('Input field for alpha')}
        colorSliderNavigationExplanationScreenReaderLabel={I18n.t(
          "You are on a color slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively"
        )}
        alphaSliderNavigationExplanationScreenReaderLabel={I18n.t(
          "You are on an alpha slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively"
        )}
        colorPaletteNavigationExplanationScreenReaderLabel={I18n.t(
          "You are on a color palette. To navigate on the palette up, left, down or right, use the 'W', 'A', 'S' and 'D' buttons respectively"
        )}
      />
    )
  }

  const renderColorPreset = (variant: ColorTab, enabled: boolean) => {
    let currColor = bgcolor
    if (variant === 'foreground') currColor = fgcolor || defaultColors[1]
    if (variant === 'border') currColor = bordercolor || '#00000000'

    let onSelectColor = handleBgColorChange
    if (variant === 'foreground') onSelectColor = handleFgColorChange
    if (variant === 'border') onSelectColor = handleBorderColorChange

    return (
      <ColorPreset
        data-testid="color-preset"
        disabled={!enabled}
        label={I18n.t('Previously chosen colors')}
        colors={[...defaultColors, ...previouslyChosenColors]}
        selected={currColor}
        onSelect={onSelectColor}
      />
    )
  }

  const renderTab = (variant: ColorTab) => {
    let choosersEnabled = true
    if (variant === 'background') {
      choosersEnabled = customBackground
    } else if (variant === 'border') {
      choosersEnabled = customBorder
    }

    return (
      <>
        {variant !== 'foreground' && (
          <View as="div" margin="0 0 small 0">
            <RadioInputGroup
              layout="columns"
              name="pickcolor"
              description={I18n.t('Pick a color')}
              size="small"
              value={choosersEnabled ? 'custom' : 'none'}
              onChange={handleChangePickAColor}
            >
              <RadioInput label={I18n.t('None')} value="none" />
              <RadioInput label={I18n.t('Custom')} value="custom" />
            </RadioInputGroup>
          </View>
        )}
        {renderColorMixer(variant, choosersEnabled)}
        {renderColorPreset(variant, choosersEnabled)}
      </>
    )
  }

  return (
    <Popover
      key={recreateKey}
      renderTrigger={
        <IconButton
          color="secondary"
          size="small"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Color')}
        >
          <IconBackgroundColor size="x-small" />
        </IconButton>
      }
      isShowingContent={isShowingContent}
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
      on="click"
      screenReaderLabel={I18n.t('Color popup')}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" padding="small" data-mce-component={true}>
        <Tabs onRequestTabChange={handleTabChange}>
          {fgcolor && (
            <Tabs.Panel
              id="foreground"
              renderTitle={I18n.t('Color')}
              isSelected={activeTab === 'foreground'}
            >
              {renderTab('foreground')}
            </Tabs.Panel>
          )}
          <Tabs.Panel
            id="background"
            renderTitle={I18n.t('Background')}
            isSelected={activeTab === 'background'}
          >
            {renderTab('background')}
          </Tabs.Panel>
          {bordercolor && (
            <Tabs.Panel
              id="border"
              renderTitle={I18n.t('Border')}
              isSelected={activeTab === 'border'}
            >
              {renderTab('border')}
            </Tabs.Panel>
          )}
        </Tabs>
        {currFgColor && !isTransparent(currBgColor) && (
          <>
            <div
              style={{
                borderTop: 'solid',
                borderWidth: '1px',
                borderColor: '#C7CDD1',
                margin: '20px 0 20px 0',
              }}
            />
            <ColorContrast
              data-testid="color-contrast"
              firstColor={currFgColor}
              secondColor={currBgColor}
              label={I18n.t('Color Contrast Ratio')}
              successLabel={I18n.t('PASS')}
              failureLabel={I18n.t('FAIL')}
              normalTextLabel={I18n.t('Normal text')}
              largeTextLabel={I18n.t('Large text')}
              graphicsTextLabel={I18n.t('Graphics text')}
              firstColorLabel={I18n.t('Foreground')}
              secondColorLabel={I18n.t('Background')}
            />
          </>
        )}
      </View>
      <View as="div" background="secondary" padding="small" textAlign="end">
        <Button onClick={() => setIsShowingContent(false)}>{I18n.t('Cancel')}</Button>
        <Button onClick={handleSubmit} margin="0 0 0 small" color="primary">
          {I18n.t('Apply')}
        </Button>
      </View>
    </Popover>
  )
}

export {ToolbarColor}
