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

import {ImageTextBlockEditPreviewProps} from './types'
import {TitleEditPreview} from '../BlockItems/Title/TitleEditPreview'
import {Flex} from '@instructure/ui-flex'
import {ImageView} from '../BlockItems/Image'
import {TextEditPreview} from '../BlockItems/Text/TextEditPreview'

export const ImageTextBlockEditPreview = ({
  title,
  altText,
  content,
  url,
  settings,
}: ImageTextBlockEditPreviewProps) => {
  return (
    <>
      {settings.includeBlockTitle && (
        <TitleEditPreview contentColor={settings.textColor} title={title} />
      )}
      <Flex direction="row" data-testid="imagetext-block-editpreview">
        <Flex.Item size="50%" align="start" padding="0 xx-small 0 0">
          <ImageView url={url} altText={altText} />
        </Flex.Item>
        <Flex.Item size="50%" padding="0 0 0 xx-small" align="start">
          <TextEditPreview contentColor={settings.textColor} content={content} />
        </Flex.Item>
      </Flex>
    </>
  )
}
