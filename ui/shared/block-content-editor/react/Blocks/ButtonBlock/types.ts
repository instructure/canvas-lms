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

import {FocusHandler} from '../../hooks/useFocusElement'
import {Prettify} from '../../utilities/Prettify'
import {TitleData} from '../BlockItems/Title/types'

export type ButtonAlignment = 'left' | 'center' | 'right'
export type ButtonLayout = 'horizontal' | 'vertical'
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

export type ButtonBlockSettings = {
  buttons: ButtonData[]
  includeBlockTitle: boolean
  alignment: ButtonAlignment
  layout: ButtonLayout
  isFullWidth: boolean
  backgroundColor: string
  titleColor: string
}

export type ButtonBlockProps = Prettify<TitleData & ButtonBlockSettings>

export type ButtonDisplayProps = Prettify<
  ButtonBlockSettings & {
    dataTestId: string
    onButtonClick?: (buttonId: number) => void
    focusHandler?: FocusHandler
  }
>

export type ButtonBlockIndividualButtonSettingsProps = {
  backgroundColor: string
  initialButtons: ButtonData[]
  onButtonsChange: (buttons: ButtonData[]) => void
}

export type ButtonBlockGeneralButtonSettingsProps = {
  alignment: ButtonAlignment
  layout: ButtonLayout
  isFullWidth: boolean
  onAlignmentChange: (alignment: ButtonAlignment) => void
  onLayoutChange: (layout: ButtonLayout) => void
  onIsFullWidthChange: (isFullWidth: boolean) => void
}

export type ButtonBlockColorSettingsProps = {
  includeBlockTitle: boolean
  backgroundColor: string
  titleColor: string
  onBackgroundColorChange: (color: string) => void
  onTitleColorChange: (color: string) => void
}

export type SingleButtonProps = {
  button: ButtonData
  isFullWidth: boolean
  onButtonClick?: (buttonId: number) => void
  focusHandler?: FocusHandler
}
