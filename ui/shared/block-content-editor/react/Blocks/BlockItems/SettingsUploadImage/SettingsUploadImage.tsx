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

import {SettingsUploadImageProps} from './types'
import {CondensedButton, IconButton} from '@instructure/ui-buttons'
import {
  IconExternalLinkLine,
  IconProgressLine,
  IconTrashLine,
  IconUploadLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useState} from 'react'
import {ImageBlockUploadModal} from '../Image/ImageBlockUploadModal'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {ModalImageData} from '../Image/types'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('block_content_editor')

export const SettingsUploadImage = ({url, fileName, onImageChange}: SettingsUploadImageProps) => {
  const [isOpen, setIsOpen] = useState(false)
  const closeModal = () => setIsOpen(false)
  const openModal = () => setIsOpen(true)

  const onSelected = (modalImageData: ModalImageData) => {
    closeModal()
    onImageChange(modalImageData)
  }

  const onDeleteImage = () => {
    onImageChange({
      url: '',
      altText: '',
      fileName: '',
      decorativeImage: false,
    })
  }

  const buttonText = url?.trim() ? I18n.t('Replace image') : I18n.t('Add image')
  const buttonIcon = url?.trim() ? <IconProgressLine /> : <IconUploadLine />

  return (
    <>
      <ImageBlockUploadModal open={isOpen} onDismiss={closeModal} onSelected={onSelected} />
      <Flex direction="column" gap="medium">
        {url?.trim() && (
          <Flex direction="row">
            <Flex.Item shouldShrink shouldGrow padding="0 medium 0 0">
              {fileName ? (
                <Text wrap="break-word">{fileName}</Text>
              ) : (
                <Link
                  target="_blank"
                  renderIcon={<IconExternalLinkLine />}
                  iconPlacement="end"
                  href={url}
                >
                  {I18n.t('Image external URL')}
                </Link>
              )}
            </Flex.Item>
            <Flex.Item>
              <IconButton
                data-testid="remove-image-button"
                screenReaderLabel={I18n.t('Remove %{fileName}', {fileName})}
                withBackground={false}
                withBorder={false}
                onClick={onDeleteImage}
              >
                <IconTrashLine />
              </IconButton>
            </Flex.Item>
          </Flex>
        )}
        <View display="block">
          <CondensedButton renderIcon={buttonIcon} onClick={openModal}>
            {buttonText}
          </CondensedButton>
        </View>
      </Flex>
    </>
  )
}
