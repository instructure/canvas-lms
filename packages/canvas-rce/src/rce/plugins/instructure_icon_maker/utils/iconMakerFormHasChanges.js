/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import _ from 'lodash'

export const hasNameChange = (initialSettings, currentSettings) => {
  return 'name' in currentSettings && initialSettings.name !== currentSettings.name
}

export const hasAltChange = (initialSettings, currentSettings) => {
  return 'alt' in currentSettings && initialSettings.alt !== currentSettings.alt
}

export const hasShapeNameChange = (initialSettings, currentSettings) => {
  return 'shape' in currentSettings && initialSettings.shape !== currentSettings.shape
}

export const hasShapeSizeChange = (initialSettings, currentSettings) => {
  return 'size' in currentSettings && initialSettings.size !== currentSettings.size
}

export const hasColorNameChange = (initialSettings, currentSettings) => {
  return 'color' in currentSettings && initialSettings.color !== currentSettings.color
}

export const hasOutlineSizeChange = (initialSettings, currentSettings) => {
  return (
    'outlineSize' in currentSettings && initialSettings.outlineSize !== currentSettings.outlineSize
  )
}

export const hasOutlineColorChange = (initialSettings, currentSettings) => {
  return (
    'outlineColor' in currentSettings &&
    initialSettings.outlineColor !== currentSettings.outlineColor
  )
}

export const hasTextChange = (initialSettings, currentSettings) => {
  return 'text' in currentSettings && initialSettings.text !== currentSettings.text
}

export const hasTextSizeChange = (initialSettings, currentSettings) => {
  return 'textSize' in currentSettings && initialSettings.textSize !== currentSettings.textSize
}

export const hasTextColorChange = (initialSettings, currentSettings) => {
  return 'textColor' in currentSettings && initialSettings.textColor !== currentSettings.textColor
}

export const hasTextBackgroundColorChange = (initialSettings, currentSettings) => {
  return (
    'textBackgroundColor' in currentSettings &&
    initialSettings.textBackgroundColor !== currentSettings.textBackgroundColor
  )
}

export const hasTextPositionChange = (initialSettings, currentSettings) => {
  return (
    'textPosition' in currentSettings &&
    initialSettings.textPosition !== currentSettings.textPosition
  )
}

export const hasImageSettingsChange = (initialSettings, currentSettings) => {
  return (
    'imageSettings' in currentSettings &&
    _.isEqual(initialSettings.imageSettings, currentSettings.imageSettings) === false
  )
}

export const hasChanges = (initialSettings, currentSettings) => {
  return [
    hasNameChange,
    hasAltChange,
    hasShapeNameChange,
    hasShapeSizeChange,
    hasColorNameChange,
    hasOutlineColorChange,
    hasOutlineSizeChange,
    hasTextChange,
    hasTextSizeChange,
    hasTextColorChange,
    hasTextBackgroundColorChange,
    hasTextPositionChange,
    hasImageSettingsChange
  ].some(func => func(initialSettings, currentSettings))
}
