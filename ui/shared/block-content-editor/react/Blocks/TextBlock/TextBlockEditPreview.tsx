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
import {Heading} from '@instructure/ui-heading'
import {type TextBlockProps} from './TextBlock'

const I18n = createI18nScope('block_content_editor')

export const TextBlockEditPreview = (props: TextBlockProps) => {
  const isTitleDefined = props.title.trim().length > 0
  const isContentDefined = props.content.trim().length > 0

  const content = isContentDefined
    ? props.content
    : `<p style="color: '#9EA6AD'">${I18n.t('Type to add body')}</p>`

  return (
    <>
      {props.settings.includeBlockTitle && (
        <Heading variant="titleSection" color={isTitleDefined ? 'primary' : 'secondary'}>
          {isTitleDefined ? props.title : I18n.t('Type to add block title')}
        </Heading>
      )}
      <div dangerouslySetInnerHTML={{__html: content}}></div>
    </>
  )
}
