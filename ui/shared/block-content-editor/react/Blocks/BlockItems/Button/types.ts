/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {FocusHandler} from '../../../hooks/useFocusElement'

export type ButtonLinkOpenMode = 'new-tab' | 'same-tab'
export type ButtonStyle = 'filled' | 'outlined'

export type ButtonData = {
  id: number
  text: string
  url: string
  linkOpenMode: ButtonLinkOpenMode
  primaryColor: string
  secondaryColor: string
  style: ButtonStyle
}

export type ButtonBaseProps = ButtonData & {
  isFullWidth: boolean
  focusHandler?: FocusHandler
}

export type ButtonViewProps = ButtonBaseProps
export type ButtonEditProps = ButtonBaseProps
export type ButtonEditViewProps = ButtonBaseProps
