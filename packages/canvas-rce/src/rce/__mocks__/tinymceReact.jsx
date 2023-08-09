/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

/*
 * This is a mock for the @tinymce/tinymce-react Editor component
 * and the inner tinymce editor object
 * jest.config.js moduleNameMapper has jest load this
 * file in response to
 * import {Editor} from '@tinymce/tinymce-react'
 * in RCEWrapper.js
 */

import React, {useEffect, useRef} from 'react'
import FakeEditor from '../__tests__/FakeEditor'

export function Editor(props) {
  const editorRef = useRef(null)
  const textareaRef = useRef(null)
  const tinymceEditor = useRef(new FakeEditor(props))
  window.tinymce.editors[0] = tinymceEditor.current

  useEffect(() => {
    tinymceEditor.current.on('change', handleChange)
    props.onInit && props.onInit({}, tinymceEditor.current)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  function handleChange(event) {
    props.onEditorChange?.(event.target.value)
  }

  return (
    <div ref={editorRef}>
      <textarea
        ref={textareaRef}
        id={props.id}
        name={props.textareaName}
        value={props.initialValue}
        onInput={handleChange}
        onChange={handleChange}
      />
    </div>
  )
}
