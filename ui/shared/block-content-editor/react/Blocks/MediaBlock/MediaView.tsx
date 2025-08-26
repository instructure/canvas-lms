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

import React from 'react'
import {View} from '@instructure/ui-view'
import {MediaData} from './types'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {Flex} from '@instructure/ui-flex'
import {DefaultPreviewImage} from '../BlockItems/DefaultPreviewImage/DefaultPreviewImage'

export const MediaView = ({src, title, titleColor, includeBlockTitle}: MediaData) => {
  return (
    <Flex gap="mediumSmall" direction="column">
      {includeBlockTitle && <TitleEditPreview title={title} contentColor={titleColor} />}
      {src ? (
        <View as="div" width="100%" height="400px">
          <iframe
            src={src}
            title={title || 'Media content'}
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
