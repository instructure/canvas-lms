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

import {TitleData} from '../BlockItems/Title/types'

export type ButtonAlignment = 'left' | 'center' | 'right'
export type ButtonLayout = 'horizontal' | 'vertical'

export type ButtonData = {
  id: number
  text: string
}

export type ButtonBlockSettings = {
  settings: {
    buttons: ButtonData[]
    includeBlockTitle: boolean
    alignment: ButtonAlignment
    layout: ButtonLayout
    isFullWidth: boolean
    backgroundColor: string
  }
}

export type ButtonBlockBase = TitleData & ButtonBlockSettings
export type ButtonBlockProps = ButtonBlockBase
export type ButtonBlockViewProps = ButtonBlockBase
export type ButtonBlockEditPreviewProps = ButtonBlockBase
export type ButtonBlockEditProps = ButtonBlockBase & {
  onTitleChange: (newTitle: string) => void
}

export type ButtonDisplayProps = ButtonBlockSettings & {
  dataTestId: string
}

export type ButtonBlockIndividualButtonSettingsProps = {
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

export type SingleButtonProps = {
  button: ButtonData
  isFullWidth: boolean
}
