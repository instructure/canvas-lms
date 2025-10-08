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

import {useScope as createI18nScope} from '@canvas/i18n'
import {IconImageLine, IconVideoLine} from '@instructure/ui-icons'

const I18n = createI18nScope('block_content_editor')

type DefaultPreviewImageProps = {
  blockType: 'image' | 'media'
}

export const DefaultPreviewImage = ({blockType}: DefaultPreviewImageProps) => {
  const ariaLabel =
    blockType === 'image' ? I18n.t('Placeholder image') : I18n.t('Placeholder media')
  return (
    <div
      role="img"
      aria-label={ariaLabel}
      className="image-block-container image-block-default-preview"
    >
      {blockType === 'image' && <IconImageLine size="large" />}
      {blockType === 'media' && <IconVideoLine size="large" />}
    </div>
  )
}
