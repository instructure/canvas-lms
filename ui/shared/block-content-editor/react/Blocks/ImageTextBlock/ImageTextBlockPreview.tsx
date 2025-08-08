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

import {ImageTextBlockPreviewProps} from './types'
import {TitlePreview} from '../BlockItems/Title/TitlePreview'
import {Flex} from '@instructure/ui-flex'
import {ImagePreview} from '../BlockItems/Image'
import {TextPreview} from '../BlockItems/Text/TextPreview'

export const ImageTextBlockPreview = ({
  title,
  altText,
  content,
  url,
  settings,
}: ImageTextBlockPreviewProps) => {
  return (
    <>
      {settings.includeBlockTitle && <TitlePreview title={title} />}
      <Flex direction="row" data-testid="imagetext-block-preview">
        <Flex.Item size="50%" align="start" padding="0 xx-small 0 0">
          <ImagePreview url={url} altText={altText} />
        </Flex.Item>
        <Flex.Item size="50%" padding="0 0 0 xx-small" align="start">
          <TextPreview content={content} />
        </Flex.Item>
      </Flex>
    </>
  )
}
