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
import React, {useEffect, useState} from 'react'
import {func, string} from 'prop-types'
import formatMessage from '../format-message'
import {SourceCodeEditor} from '@instructure/ui-source-code-editor'
import beautify from 'js-beautify'

const RceHtmlEditor = React.forwardRef(({onFocus, ...props}, editorRef) => {
  const [code, setCode] = useState(props.code)
  const label = formatMessage('html code editor')
  const [dir, setDir] = useState(getComputedStyle(document.body, null).direction)

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

  const direction = ['ltr', 'rtl'].includes(dir) ? dir : 'ltr'

  // setting height on the container keeps the RCE toolbar from jumping
  return (
    <div
      ref={editorRef}
      className="RceHtmlEditor"
      style={{height: props.height, overflow: 'hidden', textAlign: 'start'}}
    >
      <SourceCodeEditor
        label={label}
        language="html"
	// see LF-745 for tracking of the following:
        // TODO: needs prop for
        // options={{
        //   extraKeys: {Tab: false, 'Shift-Tab': false},
        // }}
        // TODO: may need
        // attachment={none | bottom | top}
        lineNumbers={true}
        lineWrapping={true}
        autoFocus={false}
        spellcheck={true}
        direction={direction}
        rtlMoveVisually={true}
        height={props.height}
        value={code}
        onChange={value => {
          setCode(value)
          props.onChange(value)
        }}
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
