/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {func, string} from 'prop-types'
import formatMessage from '../format-message'
import {CodeEditor} from '@instructure/ui-code-editor'
import beautify from 'js-beautify'

const RceHtmlEditor = React.forwardRef(({onFocus, ...props}, editorRef) => {
  const [code, setCode] = useState(props.code)
  const label = formatMessage('html code editor')
  const [dir, setDir] = useState(getComputedStyle(document.body, null).direction)
  const [codeMirrorEditorDiv, setCodeMirrorEditorDiv] = useState(null)

  useEffect(() => {
    ;(async () => {
      const p = new Promise(resolve => {
        const timerid = setInterval(() => {
          // scoping querySelector to the container div makes sure we're targeting this CodeEditor
          // The CodeMirror docs (https://codemirror.net/doc/manual.html#styling)
          // say this is the element we use to set the editor's height
          const editor = editorRef.current.querySelector('.CodeMirror')
          if (editor) {
            clearInterval(timerid)
            setCodeMirrorEditorDiv(editor)
            resolve()
          }
        }, 60)
      })
      await p
    })()
  }, [editorRef])

  useEffect(() => {
    setCode(beautify.html(props.code))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    // INSTUI sets the CodeEditor's surrounding label's
    // display inline-block so it doesn't fill the width
    // of its container unless there's wide content.
    // Override that.
    // It would be nice to use webpack's style-loader
    // but babel doesn't copy css files to its output
    // dir, and the instui babel plugin mangles class names
    // the simplest approach is to manually inject the stylesheet
    if (!document.getElementById('RceHtmlEditorStyle')) {
      const stylesheet = document.createElement('style')
      stylesheet.setAttribute('id', 'RceHtmlEditorStyle')
      stylesheet.setAttribute('type', 'text/css')
      stylesheet.textContent = `
        .RceHtmlEditor label {
          display: block;
          margin-bottom: 0;  /* get rid of the margin on CodeEditor's label */
        }
      `
      document.head.appendChild(stylesheet)
    }
    // odds are, this won't change the dir.
    setDir(getComputedStyle(editorRef.current || document.body, null).direction)
  }, [dir, editorRef])

  useEffect(() => {
    if (codeMirrorEditorDiv) {
      codeMirrorEditorDiv.CodeMirror.setSize(null, props.height)
      codeMirrorEditorDiv.style.margin = '0'
      codeMirrorEditorDiv.style.border = '0'
    }
  }, [codeMirrorEditorDiv, props.height])

  const isFocused = useRef(false)

  // move cursor to the top of the html code when the editor is focused for the first time
  const handleFocus = useCallback(
    (editor, event) => {
      if (!isFocused.current) {
        editor.setCursor(0, 0)
        isFocused.current = true
      }
      onFocus(event)
    },
    [onFocus]
  )

  // setting height on the container keeps the RCE toolbar from jumping
  return (
    <div
      ref={editorRef}
      className="RceHtmlEditor"
      style={{height: props.height, overflow: 'hidden', textAlign: 'start'}}
    >
      <CodeEditor
        label={label}
        language="html"
        options={{
          lineNumbers: true,
          lineWrapping: true,
          autofocus: false,
          spellcheck: true,
          extraKeys: {Tab: false, 'Shift-Tab': false},
          screenReaderLabel: label,
          direction: dir,
          rtlMoveVisually: true,
        }}
        value={code}
        onChange={value => {
          setCode(value)
          props.onChange(value)
        }}
        onFocus={handleFocus}
      />
    </div>
  )
})
RceHtmlEditor.propTypes = {
  code: string.isRequired,
  height: string,
  onChange: func,
  onFocus: func,
}
RceHtmlEditor.defaultProps = {
  height: 'auto',
  onChange: _value => {},
  onFocus: () => {},
}

export default RceHtmlEditor
