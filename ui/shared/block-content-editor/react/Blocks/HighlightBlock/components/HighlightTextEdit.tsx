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
import {TextArea} from '@instructure/ui-text-area'
import {useFocusElement} from '../../../hooks/useFocusElement'

const I18n = createI18nScope('block_content_editor')

export const HighlightTextEdit = ({
  content,
  setContent,
}: {content: string; setContent: (value: string) => void}) => {
  const {focusHandler} = useFocusElement()

  return (
    <TextArea
      textareaRef={element => focusHandler(element)}
      label={''}
      placeholder={I18n.t('Start typing...')}
      value={content}
      onChange={e => setContent(e.target.value)}
      resize="vertical"
    />
  )
}
