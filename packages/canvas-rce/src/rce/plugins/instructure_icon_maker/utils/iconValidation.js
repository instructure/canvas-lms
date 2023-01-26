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

export const hasBackgroundColor = settings => {
  return !!settings.color
}

export const hasText = settings => {
  return settings.text.length > 0
}

export const hasImage = settings => {
  return settings.imageSettings?.image.length > 0
}

export const hasOutline = settings => {
  return settings.outlineSize !== 'none'
}

export const validIcon = settings => {
  return [hasBackgroundColor, hasText, hasImage, hasOutline].some(func => func(settings))
}

export default validIcon
