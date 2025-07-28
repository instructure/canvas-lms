/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {IconArrowOpenDownLine, IconAttachMediaLine, IconUploadLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {
  SelectMediaModal,
  UploadRecordMediaModal,
} from '@canvas/block-editor/react/components/editor/AddMediaModals'
import {type MediaBlockProps} from './types'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('block-editor')

export const AddMediaButton = ({setProp}: {setProp: (args: any) => void}) => {
  const [showAllMediaUploadModal, setShowAllMediaUploadModal] = useState(false)
  const [showUploadRecordMediaModal, setShowUploadRecordMediaModal] = useState(false)
  const handleSave = useCallback(
    ({attachment_id, iframe_url}: {attachment_id?: string; iframe_url?: string}) => {
      setProp((prps: MediaBlockProps) => {
        prps.src = iframe_url || undefined
        prps.attachmentId = attachment_id
      })
      setShowAllMediaUploadModal(false)
    },
    [setProp],
  )

  const closeAllMediaModal = () => {
    setShowAllMediaUploadModal(false)
  }

  const openAllMediaModal = () => {
    setShowAllMediaUploadModal(true)
  }

  const closeUploadRecordMediaModal = () => {
    setShowUploadRecordMediaModal(false)
  }

  const openUploadRecordMediaModal = () => {
    setShowUploadRecordMediaModal(true)
  }

  return (
    <>
      <Menu
        label={I18n.t('Add Media')}
        trigger={
          <Button size="small">
            <Flex gap="small">
              <Text size="small">{I18n.t('Add Media')}</Text>
              <IconArrowOpenDownLine size="x-small" />
            </Flex>
          </Button>
        }
      >
        <Menu.Item value="all_media" onSelect={openUploadRecordMediaModal}>
          <IconUploadLine />
          <View as="div" display="inline-block" padding="0 0 0 x-small">
            {I18n.t('Upload / Record Media')}
          </View>
        </Menu.Item>
        <Menu.Item value="all_media" onSelect={openAllMediaModal}>
          <IconAttachMediaLine />
          <View as="div" display="inline-block" padding="0 0 0 x-small">
            {I18n.t('All Media')}
          </View>
        </Menu.Item>
      </Menu>
      <SelectMediaModal
        open={showAllMediaUploadModal}
        onSubmit={handleSave}
        onDismiss={closeAllMediaModal}
      />
      <UploadRecordMediaModal
        open={showUploadRecordMediaModal}
        onSubmit={handleSave}
        onDismiss={closeUploadRecordMediaModal}
      />
    </>
  )
}
