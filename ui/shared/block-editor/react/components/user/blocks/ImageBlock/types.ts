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

import {type SizeVariant, type ResizableProps} from '../../../editor/types'

export type ImageConstraint = 'cover' | 'contain'
export type ImageVariant = 'default' | 'hero'
export const HeroImageHeight: string = '184px'

export type ImageBlockProps = {
  src?: string
  constraint?: ImageConstraint
  alt?: string
  sizeVariant?: SizeVariant
} & ResizableProps

export const EMPTY_IMAGE_WIDTH = 100
export const EMPTY_IMAGE_HEIGHT = 100
