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
import {ColorPreset, ColorContrast} from '@instructure/ui-color-picker'
import {Popover} from '@instructure/ui-popover'
import {Tabs} from '@instructure/ui-tabs'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {IconBackgroundColor} from '../../../assets/internal-icons'

import {useScope} from '@canvas/i18n'

const I18n = useScope('block-editor')

type ToolbarColorProps = {
  bgcolor: string
  fgcolor: string
  fgcolorLabel?: string
  bgcolorLabel?: string
  onChange: (fgcolor: string, bgcolor: string) => void
}

type ColorTab = 'foreground' | 'background'

const ToolbarColor = ({
  bgcolor,
  fgcolor,
  fgcolorLabel,
  bgcolorLabel,
  onChange,
}: ToolbarColorProps) => {
  const [currFgColor, setCurrFgColor] = useState(fgcolor)
  const [currBgColor, setCurrBgColor] = useState(bgcolor)
  const [activeTab, setActiveTab] = useState<ColorTab>('foreground')
  const [isShowingContent, setIsShowingContent] = useState(false)

  useEffect(() => {
    if (!isShowingContent) {
      // reset
      setCurrFgColor(fgcolor)
      setCurrBgColor(bgcolor)
      setActiveTab('foreground')
    }
  }, [bgcolor, fgcolor, isShowingContent])

  const handleFgColorChange = useCallback((newColor: string) => {
    setCurrFgColor(newColor)
  }, [])

  const handleBgColorChange = useCallback((newColor: string) => {
    setCurrBgColor(newColor)
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

  const handleSubmit = useCallback(() => {
    setIsShowingContent(false)
    onChange(currFgColor, currBgColor)
  }, [currBgColor, currFgColor, onChange])

  const getPresetColors = (variant: ColorTab): string[] => {
    const colors = [
      '#ffffff',
      '#6c7780',
      '#394b58',
      '#111111',
      '#ec051f',
      '#d34022',
      '#e31c5b',
      '#cb34af',
      '#a34ae4',
      '#6066e6',
      '#027bc2',
      '#1d8292',
      '#05881f',
    ]
    if (variant === 'foreground') {
      const defaultTextColor = window
        .getComputedStyle(document.documentElement)
        .getPropertyValue('--ic-brand-font-color-dark')
      colors.unshift(defaultTextColor)
    }
    if (variant === 'background') {
      colors.unshift('#00000000')
    }
    return colors
  }

  const renderColorPreset = (variant: ColorTab) => {
    const value = variant === 'foreground' ? currFgColor : currBgColor
    const onSelectColor = variant === 'foreground' ? handleFgColorChange : handleBgColorChange
    const label = variant === 'foreground' ? I18n.t('Color') : I18n.t('Background Color')
    return (
      <ColorPreset
        label={label}
        colors={getPresetColors(variant)}
        selected={value}
        onSelect={onSelectColor}
      />
    )
  }

  return (
    <Popover
      renderTrigger={
        <IconButton
          color="secondary"
          themeOverride={{secondaryGhostColor: fgcolor, secondaryGhostBackground: bgcolor}}
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
          <Tabs.Panel
            id="foreground"
            renderTitle={fgcolorLabel || I18n.t('Color')}
            isSelected={activeTab === 'foreground'}
          >
            {renderColorPreset('foreground')}
          </Tabs.Panel>
          <Tabs.Panel
            id="background"
            renderTitle={bgcolorLabel || I18n.t('Background Color')}
            isSelected={activeTab === 'background'}
          >
            {renderColorPreset('background')}
          </Tabs.Panel>
        </Tabs>
        <div
          style={{
            borderTop: 'solid',
            borderWidth: '1px',
            borderColor: '#C7CDD1',
            margin: '20px 0 20px 0',
          }}
        />
        <ColorContrast
          firstColor={currBgColor}
          secondColor={currFgColor}
          label="Color Contrast Ratio"
          successLabel="PASS"
          failureLabel="FAIL"
          normalTextLabel="Normal text"
          largeTextLabel="Large text"
          graphicsTextLabel="Graphics text"
          firstColorLabel="Background"
          secondColorLabel="Foreground"
        />
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
