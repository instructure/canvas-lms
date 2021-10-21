/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {Popover} from '@instructure/ui-popover'
import {IconArrowOpenDownLine, IconArrowOpenUpLine} from '@instructure/ui-icons'
import {BaseButton, CloseButton, IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import PreviewIcon from './PreviewIcon'

import formatMessage from '../../../format-message'

const COLORS = [
  '#BD3C14',
  '#FF2717',
  '#E71F63',
  '#8F3E97',
  '#65499D',
  '#4554A4',
  '#1770AB',
  '#0B9BE3',
  '#06A3B7',
  '#009688',
  '#009606',
  '#8D9900',
  '#D97900',
  '#FD5D10',
  '#F06291',
  '#111111',
  '#556572',
  '#8B969E',
  '#FFFFFF',
  null
]

export const ColorInput = ({color, label, name, onChange, popoverMountNode, width = '11rem'}) => {
  const [isOpen, setIsOpen] = useState(false)
  const [inputValue, setInputValue] = useState(color)

  useEffect(() => {
    setInputValue(color)
  }, [color])

  // fire onChange in case value is valid
  const handleColorChange = hex => {
    if (isValidHex(hex)) {
      onChange(hex)
    }
    if (!hex || !hex.length) {
      onChange(null)
    }
    setInputValue(hex)
  }

  // reset the input value on blur if invalid
  const handleInputBlur = () => {
    if (!inputValue || (inputValue.length > 0 && !isValidHex(inputValue))) {
      setInputValue(color)
    }
  }

  function renderPopover() {
    return (
      <Popover
        on="click"
        isShowingContent={isOpen}
        onShowContent={() => setIsOpen(true)}
        onHideContent={() => setIsOpen(false)}
        shouldContainFocus
        shouldReturnFocus
        mountNode={popoverMountNode}
        renderTrigger={
          <IconButton
            screenReaderLabel={formatMessage('View predefined colors')}
            size="small"
            withBackground={false}
            withBorder={false}
          >
            {isOpen ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
          </IconButton>
        }
      >
        <CloseButton placement="end" onClick={() => setIsOpen(false)}>
          {formatMessage('Close')}
        </CloseButton>
        <Flex
          alignItems="center"
          as="div"
          justifyItems="center"
          padding="x-large x-small small"
          width="175px"
          wrapItems
        >
          {COLORS.map(hex => (
            <ColorPreview
              key={`${name}-${hex}`}
              color={hex}
              disabled={!isOpen}
              onSelect={() => handleColorChange(hex)}
            />
          ))}
        </Flex>
      </Popover>
    )
  }

  return (
    <View as="div">
      <TextInput
        display="inline-block"
        name={name}
        onBlur={handleInputBlur}
        onChange={(e, value) => handleColorChange(value)}
        placeholder={formatMessage('None')}
        renderBeforeInput={<ColorPreview color={color} disabled margin="0" />}
        renderAfterInput={renderPopover()}
        renderLabel={label}
        shouldNotWrap
        value={inputValue || ''}
        width={width}
      />
    </View>
  )
}

function ColorPreview({color, disabled, margin = 'xxx-small', onSelect}) {
  return (
    <BaseButton
      interaction={disabled ? 'readonly' : undefined}
      isCondensed
      margin={margin}
      onClick={onSelect}
      size="small"
      tabIndex={onSelect ? 0 : -1}
      withBackground={false}
      withBorder={false}
    >
      {!disabled && (
        <ScreenReaderContent>
          {color ? formatMessage('Color {color}', {color}) : formatMessage('None')}
        </ScreenReaderContent>
      )}
      <PreviewIcon
        color={color}
        testId={`colorPreview-${color}`}
      />
    </BaseButton>
  )
}

function isValidHex(color) {
  if (!color) return false

  switch (color.length) {
    case 4:
      return /^#[0-9A-F]{3}$/i.test(color)
    case 7:
      return /^#[0-9A-F]{6}$/i.test(color)
    default:
      return false
  }
}
