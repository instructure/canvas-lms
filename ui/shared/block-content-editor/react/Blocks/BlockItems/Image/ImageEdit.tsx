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
import {useState} from 'react'
import {ImageBlockUploadModal} from './ImageBlockUploadModal'
import {AddButton} from '../AddButton/AddButton'
import {ImageEditProps, ModalImageData} from './types'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconUploadLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {useBlockContentEditorContext} from '../../../BlockContentEditorContext'
import {useNode} from '@craftjs/core'
import {ImageCaption} from './ImageCaption'

const I18n = createI18nScope('block_content_editor')

export const ImageEdit = ({
  onImageChange,
  url,
  altText,
  caption,
  altTextAsCaption,
  focusHandler,
}: ImageEditProps) => {
  const [isOpen, setIsOpen] = useState(false)
  const {settingsTray} = useBlockContentEditorContext()
  const {id} = useNode()

  const closeModal = () => setIsOpen(false)
  const openModal = () => setIsOpen(true)
  const onSelected = (modalImageData: ModalImageData) => {
    closeModal()
    onImageChange(modalImageData)
  }

  const calculatedCaption = altTextAsCaption ? altText : caption

  return (
    <Flex direction="column" gap="mediumSmall">
      <ImageBlockUploadModal open={isOpen} onDismiss={closeModal} onSelected={onSelected} />

      <div className="image-actions-container">
        {url ? (
          <>
            <img src={url} alt={altText} />
            <div className="image-actions">
              <IconButton
                renderIcon={<IconUploadLine />}
                onClick={openModal}
                screenReaderLabel={I18n.t('Change image')}
                size="small"
                elementRef={
                  focusHandler ? element => focusHandler(element as HTMLElement) : undefined
                }
              />
            </div>
          </>
        ) : (
          <AddButton onClick={() => setIsOpen(true)} focusHandler={focusHandler} />
        )}
      </div>
      <Flex direction="row" gap="x-small">
        <ImageCaption>{calculatedCaption || I18n.t('Image caption')}</ImageCaption>
        <IconButton
          data-testid="edit-block-image"
          screenReaderLabel={I18n.t('Edit block')}
          onClick={() => settingsTray.open(id)}
          size="small"
        >
          <IconEditLine fontSize="small" />
        </IconButton>
      </Flex>
    </Flex>
  )
}
