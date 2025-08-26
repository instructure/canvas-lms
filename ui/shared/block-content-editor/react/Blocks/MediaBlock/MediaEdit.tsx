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

import React, {useCallback, useState} from 'react'
import {useNode} from '@craftjs/core'
import {View} from '@instructure/ui-view'
import {UploadMediaModal} from './UploadMediaModal'
import {MediaData, MediaBlockEditProps} from './types'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {Flex} from '@instructure/ui-flex'
import {AddButton} from '../BlockItems/AddButton/AddButton'

export const MediaEdit = (props: MediaBlockEditProps) => {
  const {
    actions: {setProp},
  } = useNode()

  const [showUploadRecordMediaModal, setShowUploadRecordMediaModal] = useState(false)

  const handleSave = useCallback(
    (iframe_url: string) => {
      setProp((props: MediaData) => {
        if (iframe_url) {
          props.src = iframe_url
        }
      })
      setShowUploadRecordMediaModal(false)
    },
    [setProp],
  )

  return (
    <Flex gap="mediumSmall" direction="column">
      {props.includeBlockTitle && (
        <TitleEdit title={props.title || ''} onTitleChange={props.onTitleChange} />
      )}
      {props.src ? (
        <View as="div" width={'100%'} height={'400px'}>
          <iframe
            src={props.src}
            title={props.title || 'Media content'}
            width="100%"
            height="100%"
            style={{
              border: 'none',
              borderRadius: '4px',
            }}
            allow="fullscreen"
            data-media-type="video"
          />
        </View>
      ) : (
        <AddButton onClick={() => setShowUploadRecordMediaModal(true)} />
      )}
      <UploadMediaModal
        open={showUploadRecordMediaModal}
        onSubmit={handleSave}
        onDismiss={() => setShowUploadRecordMediaModal(false)}
      />
    </Flex>
  )
}
