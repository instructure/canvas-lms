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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('color_picker_colors')

export type Color = {
  name: string
  hexcode: string
}

export const defaultColors: Record<string, string> = {
  salmon: '#FFE8E5',
  orange: '#FEF0E5',
  yellow: '#FEF7E5',
  brown: '#F3EFEA',
  green: '#E5F7E5',
  blue: '#E5F3FC',
  steel: '#E9EDF5',
  pink: '#F8EAF6',
  lavender: '#F0E8EF',
  white: '#FFFFFF',
}

export const defaultColorLabels: Record<string, string> = {
  salmon: I18n.t('Salmon'),
  orange: I18n.t('Orange'),
  yellow: I18n.t('Yellow'),
  brown: I18n.t('Brown'),
  green: I18n.t('Green'),
  blue: I18n.t('Blue'),
  steel: I18n.t('Steel'),
  pink: I18n.t('Pink'),
  lavender: I18n.t('Lavender'),
  white: I18n.t('White'),
}

export const colorPickerColors = Object.keys(defaultColors).reduce((obj: Color[], key: string) => {
  obj.push({hexcode: defaultColors[key], name: key})
  return obj
}, [])
