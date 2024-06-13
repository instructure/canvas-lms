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

import React from 'react'
import {
  IconAnnouncementLine,
  IconGradebookLine,
  IconModuleLine,
  IconVideoLine,
  IconArrowUpLine,
  IconLikeLine,
} from '@instructure/ui-icons'
import {type IconProps} from '../iconTypes'

export const IconAnnouncement = ({elementRef, size = 'small'}: IconProps) => {
  return <IconAnnouncementLine elementRef={elementRef} size={size} />
}

export const IconVideo = ({elementRef, size = 'small'}: IconProps) => {
  return <IconVideoLine elementRef={elementRef} size={size} />
}

export const IconModule = ({elementRef, size = 'small'}: IconProps) => {
  return <IconModuleLine elementRef={elementRef} size={size} />
}

export const IconGradebook = ({elementRef, size = 'small'}: IconProps) => {
  return <IconGradebookLine elementRef={elementRef} size={size} />
}

export const IconArrowUp = ({elementRef, size = 'small'}: IconProps) => {
  return <IconArrowUpLine elementRef={elementRef} size={size} />
}

export const IconLike = ({elementRef, size = 'small'}: IconProps) => {
  return <IconLikeLine elementRef={elementRef} size={size} />
}
