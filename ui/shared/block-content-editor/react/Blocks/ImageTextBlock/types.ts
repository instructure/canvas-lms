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

import {ImageData} from '../BlockItems/Image/types'
import {TextData} from '../BlockItems/Text/types'
import {TitleData} from '../BlockItems/Title/types'

export type ArrangementOption = 'left' | 'right'
export type TextToImageRatioOption = '1:1' | '2:1'
export type ImageTextSettings = {
  settings: {
    includeBlockTitle: boolean
    backgroundColor: string
    textColor: string
    arrangement: ArrangementOption
    textToImageRatio: TextToImageRatioOption
  }
}
export type ImageTextData = TextData & ImageData
export type ImageTextEditHandlers = {
  onTitleChange: (title: string) => void
  onContentChange: (content: string) => void
  onImageChange: (imageData: ImageData) => void
}

export type ImageTextBlockBase = ImageTextData & ImageTextSettings & TitleData
export type ImageTextBlockProps = ImageTextBlockBase
export type ImageTextBlockEditProps = ImageTextBlockBase & ImageTextEditHandlers
export type ImageTextBlockEditPreviewProps = ImageTextBlockBase
export type ImageTextBlockViewProps = ImageTextBlockBase
