/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {forwardRef, useEffect} from 'react'

interface CanvasRceProps {
  textareaId?: string
  defaultContent?: string
  onContentChange?: (content: string) => void
  onInit?: () => void
  [key: string]: any
}

const CanvasRce = forwardRef<any, CanvasRceProps>(
  (
    {
      textareaId = 'textarea',
      defaultContent = '',
      onContentChange,
      onInit,
      editorOptions,
      renderKBShortcutModal,
      autosave,
      height,
      ...props
    },
    ref,
  ) => {
    useEffect(() => {
      if (onInit) {
        onInit()
      }
    }, [onInit])

    const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      if (onContentChange) {
        onContentChange(e.target.value)
      }
    }

    return (
      <textarea
        id={textareaId}
        data-testid={`rce-${textareaId}`}
        defaultValue={defaultContent}
        onChange={handleChange}
        style={{height: typeof height === 'number' ? `${height}px` : height}}
        {...props}
      />
    )
  },
)

CanvasRce.displayName = 'CanvasRce'

export default CanvasRce
