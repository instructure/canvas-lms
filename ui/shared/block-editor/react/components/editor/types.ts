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
import {type ViewOwnProps} from '@instructure/ui-view'

export interface RenderNodeProps {
  render: React.ReactElement
}

export type AddSectionPlacement = 'prepend' | 'append' | undefined
export type SizeVariant = 'auto' | 'pixel' | 'percent'

export type Sz = {
  width: number
  height: number
}

export type ResizableProps = {
  width?: number
  height?: number
  maintainAspectRatio?: boolean
}

export type OnRequestTabChangeHandler = (
  event: React.MouseEvent<ViewOwnProps, MouseEvent> | React.KeyboardEvent<ViewOwnProps>,
  tabData: {index: number; id?: string | undefined},
) => void
