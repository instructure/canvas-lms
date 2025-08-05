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
import {uid} from '@instructure/uid'
import {type TextBlockProps} from './TextBlock'
import {Flex} from '@instructure/ui-flex'
import {TitleEdit} from '../BlockItems/Title/TitleEdit'

export const TextBlockEdit = (
  props: TextBlockProps & {
    onTitleChange: (newTitle: string) => void
    onContentChange: (newContent: string) => void
  },
) => {
  const rceRef = useRef(null)

  return (
    <Flex direction="column" gap="mediumSmall">
      {props.settings.includeBlockTitle && (
        <TitleEdit title={props.title} onTitleChange={props.onTitleChange} />
      )}
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
    </Flex>
  )
}
