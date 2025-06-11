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

import {useState} from 'react'
import {ImageBlockAddButton} from './ImageBlockAddButton'
import {ImageBlockUploadModal} from './ImageBlockUploadModal'
import {useSave} from '../BaseBlock/useSave'
import {ImageBlock, ImageBlockProps} from './ImageBlock'

export const ImageBlockEdit = (props: ImageBlockProps) => {
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
  return (
    <>
      <ImageBlockUploadModal open={isOpen} onDismiss={closeModal} onSelected={onSelected} />
      {props.url ? (
        <img src={props.url} alt="" className="image-block-preview" />
      ) : (
        <ImageBlockAddButton onClick={() => setIsOpen(true)} />
      )}
    </>
  )
}
