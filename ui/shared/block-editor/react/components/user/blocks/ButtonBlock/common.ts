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

export const instuiButtonColors = [
  'primary',
  'secondary',
  'success',
  'danger',
  'primary-inverse',
] as const
export type InstuiButtonColor = (typeof instuiButtonColors)[number]

export const isInstuiButtonColor = (value: any): value is InstuiButtonColor => {
  return (instuiButtonColors as readonly string[]).includes(value)
}

export type IconSize = 'x-small' | 'small'
export type ButtonSize = 'small' | 'medium' | 'large'
export type ButtonVariant = 'condensed' | 'outlined' | 'filled'

export type ButtonBlockProps = {
  text: string
  size?: ButtonSize
  variant?: ButtonVariant
  color?: InstuiButtonColor | string
  iconName?: string
  iconSize?: IconSize
  href?: string
}
