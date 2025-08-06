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
import {uid} from '@instructure/uid'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {TextEditProps} from './types'

export const TextEdit = ({content, height, onContentChange}: TextEditProps) => {
  const rceRef = useRef(null)

  return (
    <CanvasRce
      ref={rceRef}
      autosave={false}
      textareaId={uid('rceblock')}
      variant="text-block"
      defaultContent={content}
      onContentChange={onContentChange}
      editorOptions={{
        focus: false,
      }}
      height={height}
    />
  )
}
