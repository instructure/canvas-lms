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
import RCEWrapper from '@instructure/canvas-rce/es/rce/RCEWrapper'
import './text-edit.css'

export const TextEdit = ({content, height, onContentChange, focusHandler}: TextEditProps) => {
  const rceRef = useRef<RCEWrapper | null>(null)
  return (
    <div className="text-edit-wrapper">
      <CanvasRce
        ref={rceRef}
        autosave={false}
        textareaId={uid('rceblock')}
        variant="block-content-editor"
        defaultContent={content}
        onContentChange={onContentChange}
        height={height}
        onInit={() => {
          focusHandler && focusHandler(rceRef.current)
        }}
      />
    </div>
  )
}
