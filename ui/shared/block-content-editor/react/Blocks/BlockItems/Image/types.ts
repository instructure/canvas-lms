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

type ImageMetadata = {
  url?: string
  altText?: string
  decorativeImage?: boolean
}

type ImageCaption = {
  caption?: string
}

type ImageSettingAltAsCaption = {
  altTextAsCaption?: boolean
}

type ImageFileData = {
  fileName?: string
}

export type ImageData = ImageMetadata & ImageFileData & ImageSettingAltAsCaption & ImageCaption
export type ModalImageData = ImageMetadata & ImageFileData
export type ImageChangeHandler = {
  onImageChange: (data: ImageData) => void
}
export type ImageEditProps = ImageData &
  ImageChangeHandler & {
    focusHandler?: FocusHandler | false
  }
export type ImageViewProps = ImageData
