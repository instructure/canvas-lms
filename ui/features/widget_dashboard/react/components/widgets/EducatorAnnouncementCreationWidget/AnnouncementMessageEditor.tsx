/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useImperativeHandle, useRef} from 'react'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import type RCEWrapper from '@instructure/canvas-rce/es/rce/RCEWrapper'
import type {MessageEditorProps} from '@instructure/platform-widget-dashboard'

export const AnnouncementMessageEditor = ({
  onChange,
  id,
  disabled,
  elementRef,
}: MessageEditorProps) => {
  const rceRef = useRef<RCEWrapper | null>(null)

  useImperativeHandle(elementRef, () => ({focus: () => rceRef.current?.focus()}), [])

  return (
    <CanvasRce
      ref={rceRef}
      textareaId={id}
      variant="block-content-editor"
      autosave={false}
      readOnly={disabled}
      onContentChange={onChange}
      height={300}
      mirroredAttrs={{'aria-required': 'true'}}
    />
  )
}
// Platform-UI calls this as a function, not JSX. Without the wrapper,
// React can't track the hooks inside and they break when the branch toggles.
export const renderAnnouncementMessageEditor = (props: MessageEditorProps) => (
  <AnnouncementMessageEditor {...props} />
)
