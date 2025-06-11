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

import './image-block.css'
import {useScope as createI18nScope} from '@canvas/i18n'
import {BaseBlock, useIsEditMode} from '../BaseBlock'
import {ImageBlockAddButton} from './ImageBlockAddButton'
import {ImageBlockDefaultPreviewImage} from './ImageBlockDefaultPreviewImage'
import {useState} from 'react'
import {ImageBlockUploadModal} from './ImageBlockUploadModal'

const I18n = createI18nScope('page_editor')

const ImageBlockEdit = () => {
  const [isOpen, setIsOpen] = useState(false)
  return (
    <>
      <ImageBlockUploadModal open={isOpen} />
      <ImageBlockAddButton onClick={() => setIsOpen(true)} />
    </>
  )
}

const ImageBlockEditPreview = () => {
  return <ImageBlockDefaultPreviewImage />
}

const ImageBlockContent = () => {
  const isEditMode = useIsEditMode()
  return isEditMode ? <ImageBlockEdit /> : <ImageBlockEditPreview />
}

export const ImageBlock = () => {
  return (
    <BaseBlock title={I18n.t('Image Block')}>
      <ImageBlockContent />
    </BaseBlock>
  )
}
