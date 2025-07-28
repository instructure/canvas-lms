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

import {useRef} from 'react'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {useScope as createI18nScope} from '@canvas/i18n'
import {uid} from '@instructure/uid'
import {TextInput} from '@instructure/ui-text-input'

const I18n = createI18nScope('page_editor')

export const TextBlockEdit = (props: {
  title: string
  content: string
  onTitleChange: (newTitle: string) => void
  onContentChange: (newContent: string) => void
}) => {
  const rceRef = useRef(null)

  return (
    <>
      <TextInput
        renderLabel={I18n.t('Block title')}
        placeholder={I18n.t('Start typing...')}
        value={props.title}
        onChange={e => props.onTitleChange(e.target.value)}
      />
      <CanvasRce
        ref={rceRef}
        autosave={false}
        textareaId={uid('rceblock')}
        variant="text-block"
        defaultContent={props.content}
        onContentChange={props.onContentChange}
        editorOptions={{
          focus: false,
        }}
        height={300}
      />
    </>
  )
}
