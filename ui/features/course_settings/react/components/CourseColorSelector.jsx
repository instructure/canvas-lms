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

import React, {useState} from 'react'
import {string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {darken} from '@instructure/ui-color-utils'
import {IconButton} from '@instructure/ui-buttons'
import {IconCheckMarkSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('course_color_selector')

export const COLOR_OPTIONS = [
  '#AF4525',
  '#EB412D',
  '#D43964',
  '#854493',
  '#614C98',
  '#48559F',
  '#356FA6',
  '#459ADD',
  '#49A1B4',
  '#429488',
  '#42932B',
  '#8F982E',
  '#CC7D2D',
  '#EB6730',
  '#DF6B91',
]
const PREVIEW_SIZE = 16

function ColorPreview({color = '#FFF'}) {
  return (
    <span
      style={{
        display: 'block',
        backgroundColor: color,
        border: '1px solid #73818C',
        borderRadius: '3px',
        height: `${PREVIEW_SIZE}px`,
        width: `${PREVIEW_SIZE}px`,
      }}
      data-testid="course-color-preview"
    >
      {' '}
    </span>
  )
}

// Correctly implements modulo for negative numbers instead of remainder.
// See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Remainder
const mod = (n, m) => ((n % m) + m) % m

const handleOptionNavigation =
  (focusedColorIndex = 0, onChangeFocus) =>
  e => {
    if (e.keyCode !== 37 && e.keyCode !== 39) return
    const offset = e.keyCode - 38
    const newIndex = mod(focusedColorIndex + offset, COLOR_OPTIONS.length)
    onChangeFocus(newIndex)
    document.getElementById(`color-${COLOR_OPTIONS[newIndex]}`).focus()
  }

const getSelectedColorIndex = color => {
  const selectedColorIndex = COLOR_OPTIONS.indexOf(color)
  return selectedColorIndex >= 0 ? selectedColorIndex : 0
}

function ColorOptions({color, focusedColorIndex, onChange, onChangeFocus}) {
  return (
    <View as="section" onKeyDown={handleOptionNavigation(focusedColorIndex, onChangeFocus)}>
      <ScreenReaderContent>
        {I18n.t(
          'Set course color to a preset hexadecimal color code. Use the left and right arrow keys to navigate presets.'
        )}
      </ScreenReaderContent>
      {COLOR_OPTIONS.map((option, i) => (
        <IconButton
          id={`color-${option}`}
          key={`color-${option}`}
          onClick={() => onChange(option)}
          screenReaderLabel={option}
          margin="0 x-small x-small 0"
          size="small"
          color="secondary"
          themeOverride={{
            secondaryColor: 'white',
            secondaryBackground: option,
            secondaryBorderColor: option,
            secondaryHoverBackground: darken(option, 10),
            secondaryActiveBackground: darken(option, 10),
          }}
          tabIndex={focusedColorIndex === i ? 0 : -1}
          aria-pressed={color === option}
        >
          {color === option ? <IconCheckMarkSolid /> : ' '}
        </IconButton>
      ))}
    </View>
  )
}

const validateColorString = (oldColor, color) => {
  // Allow the auto-populated pound sign to be deleted
  if (oldColor.length === 1 && !color) {
    return ''
  }
  const newColor = color
    .replace(/#/g, '')
    .replace(/[^\da-fA-F]/g, '')
    .substring(0, 6)
  return `#${newColor}`
}

export default function CourseColorSelector({courseColor}) {
  const [color, setColor] = useState(courseColor || '')
  const [focusedColorIndex, setFocusedColorIndex] = useState(() => getSelectedColorIndex(color))
  return (
    <View as="section" margin="0 0 small 0">
      <ColorOptions
        color={color}
        focusedColorIndex={focusedColorIndex}
        onChange={setColor}
        onChangeFocus={setFocusedColorIndex}
      />
      <TextInput
        renderBeforeInput={<ColorPreview color={color} />}
        renderLabel={
          <ScreenReaderContent>
            {I18n.t('Set course color to a custom hexadecimal code')}
          </ScreenReaderContent>
        }
        name="course[course_color]"
        value={color || ''}
        onChange={(_, newColor) => setColor(validateColorString(color, newColor))}
        display="inline-block"
        width="10rem"
        shouldNotWrap={true}
      />
    </View>
  )
}

CourseColorSelector.propTypes = {
  courseColor: string,
}
