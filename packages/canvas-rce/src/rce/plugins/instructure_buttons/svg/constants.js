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

export const DEFAULT_SETTINGS = {
  name: '',
  alt: '',
  shape: 'square',
  size: 'small',
  color: null,
  outlineColor: null,
  outlineSize: 'none',
  text: '',
  textSize: 'small',
  textColor: null,
  textBackgroundColor: null,
  textPosition: 'middle'
}

export const DEFAULT_OPTIONS = {
  isPreview: false
}

export const BASE_SIZE = {
  'x-small': 74,
  small: 122,
  medium: 158,
  large: 218
}

export const STROKE_WIDTH = {
  none: 0,
  small: 2,
  medium: 4,
  large: 8
}

export const TEXT_SIZE = {
  small: 14,
  medium: 16,
  large: 22,
  'x-large': 28
}

export const MAX_CHAR_COUNT = {
  small: 21,
  medium: 18,
  large: 13,
  'x-large': 10
}

export const MAX_TOTAL_TEXT_CHARS = 32

export const TEXT_BACKGROUND_PADDING = 4
