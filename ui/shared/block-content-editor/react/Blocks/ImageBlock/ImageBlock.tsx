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
import {ImageActionsWrapper} from './ImageActionsWrapper'
import {useState} from 'react'
import {useSave} from '../BaseBlock/useSave'
import {ImageBlockUploadModal} from './ImageBlockUploadModal'
import {ImageBlockAddButton} from './ImageBlockAddButton'
import {ImageBlockDefaultPreviewImage} from './ImageBlockDefaultPreviewImage'

const I18n = createI18nScope('page_editor')

const ImageBlockContent = (props: ImageBlockProps) => {
  const isEditMode = useIsEditMode()
  const [isOpen, setIsOpen] = useState(false)
  const save = useSave<typeof ImageBlock>()
  const closeModal = () => setIsOpen(false)
  const onSelected = (url: string, altText: string) => {
    closeModal()
    save({
      url,
      altText,
    })
  }

  const image = props.url ? <img src={props.url} alt={props.altText} /> : undefined
  return (
    <>
      {isEditMode && (
        <ImageBlockUploadModal open={isOpen} onDismiss={closeModal} onSelected={onSelected} />
      )}

      <ImageActionsWrapper
        showActions={isEditMode && !!image}
        onUploadClick={() => setIsOpen(true)}
      >
        {isEditMode
          ? (image ?? <ImageBlockAddButton onClick={() => setIsOpen(true)} />)
          : (image ?? <ImageBlockDefaultPreviewImage />)}
      </ImageActionsWrapper>
    </>
  )
}

export type ImageBlockProps = {
  url: string | undefined
  altText: string | undefined
}

export const ImageBlock = (props: ImageBlockProps) => {
  return (
    <BaseBlock title={I18n.t('Image Block')}>
      <ImageBlockContent {...props} />
    </BaseBlock>
  )
}
