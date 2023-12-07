/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {FormField} from '@instructure/ui-form-field'
import CanvasRce from '@canvas/rce/react/CanvasRce'

type RichTextEditProps = {
  id: string
  content: string
  label: string
  onContentChange: (content: string) => void
}

const RichTextEdit = ({id, content, label, onContentChange}: RichTextEditProps) => {
  const [currContent, setCurrContent] = useState(content)
  const [tinymce, setTinymce] = useState<unknown>(null)
  const rceRef = useRef(null)

  useEffect(() => {
    if (tinymce) {
      setCurrContent(content)
      // @ts-expect-error
      tinymce.setContent(content.trim())
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tinymce])

  const handleInitRce = useCallback((tinyeditor: unknown) => {
    setTinymce(tinyeditor)
  }, [])

  const handleContentChange = useCallback(
    (newContent: string) => {
      if (tinymce) {
        setCurrContent(newContent)
        onContentChange(newContent)
      }
    },
    [onContentChange, tinymce]
  )

  return (
    <FormField id={`${id}_label`} label={label}>
      <div style={{marginTop: '-.75rem', position: 'relative'}}>
        <textarea id={`${id}_text`} style={{display: 'none'}} />
        <CanvasRce
          ref={rceRef}
          autosave={false}
          defaultContent={currContent}
          height={300}
          textareaId={`${id}_text`}
          onInit={handleInitRce}
          onContentChange={handleContentChange}
        />
      </div>
    </FormField>
  )
}

export default RichTextEdit
