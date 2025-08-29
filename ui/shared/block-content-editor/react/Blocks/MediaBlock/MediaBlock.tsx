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

import React, {useState} from 'react'
import {MediaBlockSettings} from './MediaBlockSettings'
import {BaseBlock} from '../BaseBlock'
import {MediaBlockProps} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useSave} from '../BaseBlock/useSave'
import {Flex} from '@instructure/ui-flex'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {View} from '@instructure/ui-view'
import {DefaultPreviewImage} from '../BlockItems/DefaultPreviewImage/DefaultPreviewImage'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'
import {AddButton} from '../BlockItems/AddButton/AddButton'
import {UploadMediaModal} from './UploadMediaModal'

const I18n = createI18nScope('block_content_editor')

const MediaBlockView = (props: MediaBlockProps) => {
  return (
    <Flex gap="mediumSmall" direction="column">
      {props.includeBlockTitle && (
        <TitleEditPreview title={props.title} contentColor={props.titleColor} />
      )}
      {props.src ? (
        <View as="div" width="100%" height="400px">
          <iframe
            src={props.src}
            title={props.title || 'Media content'}
            width="100%"
            height="100%"
            allow="fullscreen"
            data-media-type="video"
          />
        </View>
      ) : (
        <DefaultPreviewImage blockType="media" />
      )}
    </Flex>
  )
}

const MediaBlockEdit = (props: MediaBlockProps) => {
  const [title, setTitle] = useState(props.title)
  const [showModal, setShowModal] = useState(false)

  const save = useSave(() => ({
    title,
  }))

  return (
    <Flex gap="mediumSmall" direction="column">
      {props.includeBlockTitle && <TitleEdit title={title} onTitleChange={setTitle} />}
      {props.src ? (
        <View as="div" width={'100%'} height={'400px'}>
          <iframe
            src={props.src}
            title={title || 'Media content'}
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
        <AddButton onClick={() => setShowModal(true)} />
      )}
      <UploadMediaModal
        open={showModal}
        onSubmit={(src: string) => save({src})}
        onDismiss={() => setShowModal(false)}
      />
    </Flex>
  )
}

export const MediaBlock = (props: MediaBlockProps) => {
  return (
    <BaseBlock
      ViewComponent={MediaBlockView}
      EditComponent={MediaBlockEdit}
      EditViewComponent={MediaBlockView}
      componentProps={props}
      title={MediaBlock.craft.displayName}
      backgroundColor={props.backgroundColor}
    />
  )
}

MediaBlock.craft = {
  displayName: I18n.t('Media'),
  related: {
    settings: MediaBlockSettings,
  },
}
