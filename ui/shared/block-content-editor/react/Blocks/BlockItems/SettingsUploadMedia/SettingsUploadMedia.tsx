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

import {CondensedButton} from '@instructure/ui-buttons'
import {IconUploadLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {UploadMediaModal} from '../../MediaBlock/UploadMediaModal'
import {MediaSources} from '../../MediaBlock/types'

const I18n = createI18nScope('block_content_editor')

type SettingsUploadMediaProps = {
  url: string
  onMediaChange: (data: MediaSources) => void
}

export const SettingsUploadMedia = ({url, onMediaChange}: SettingsUploadMediaProps) => {
  const [isOpen, setIsOpen] = useState(false)
  const closeModal = () => setIsOpen(false)
  const openModal = () => setIsOpen(true)

  const onSelected = (data: MediaSources) => {
    closeModal()
    onMediaChange(data)
  }

  const buttonText = url?.trim() ? I18n.t('Replace media') : I18n.t('Choose media')

  return (
    <>
      <UploadMediaModal open={isOpen} onDismiss={closeModal} onSubmit={onSelected} />
      <Flex direction="column" gap="medium">
        <View display="block">
          <CondensedButton renderIcon={<IconUploadLine />} onClick={openModal}>
            {buttonText}
          </CondensedButton>
        </View>
      </Flex>
    </>
  )
}
