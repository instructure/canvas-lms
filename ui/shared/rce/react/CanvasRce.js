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

import React, {forwardRef, useEffect, useState} from 'react'
import {bool, func, number, object, objectOf, oneOfType, string} from 'prop-types'
import {createChainedFunction} from '@instructure/ui-utils'
import TheRealRce from '@instructure/canvas-rce/es/rce/CanvasRce'
import getRCSProps from '../getRCSProps'
import closedCaptionLanguages from '@canvas/util/closedCaptionLanguages'
import EditorConfig from '../tinymce.config'

const CanvasRce = forwardRef(function CanvasRce(props, rceRef) {
  const {
    autosave,
    defaultContent,
    mirroredAttrs,
    readOnly,
    textareaClassName,
    textareaId,
    height,
    editorOptions,
    onFocus,
    onBlur,
    onContentChange,
    onInit,
    ...rest
  } = props

  const [languages] = useState(() => {
    const myLanguage = ENV.LOCALE

    const langlist = Object.keys(closedCaptionLanguages)
      .map(locale => {
        return {id: locale, label: closedCaptionLanguages[locale]}
      })
      .sort((a, b) => {
        if (a.id === myLanguage) {
          return -1
        } else if (b.id === myLanguage) {
          return 1
        } else {
          return a.label.localeCompare(b.label, myLanguage)
        }
      })
    return langlist
  })
  const [RCSProps] = useState(getRCSProps())
  const [tinymceConfig] = useState(() => {
    // tinymce is a global by now via import of CanvasRce importing tinyRCE
    const editorConfig = new EditorConfig(tinymce, window.INST, textareaId)
    const config = {...editorConfig.defaultConfig(), ...editorOptions}
    config.init_instance_callback = createChainedFunction(
      config.init_instance_callback,
      editorOptions.init_instance_callback
    )
    return config
  })
  const [autosave_] = useState({
    enabled: ENV.rce_auto_save && autosave,
    interval: Number.isNaN(ENV.rce_auto_save_max_age_ms) ? 3600000 : ENV.rce_auto_save_max_age_ms
  })

  useEffect(() => {
    const rce_wrapper = rceRef.current
    return () => {
      rce_wrapper?.destroy()
    }
  }, [rceRef])

  return (
    <TheRealRce
      ref={rceRef}
      autosave={autosave_}
      defaultContent={defaultContent}
      editorOptions={tinymceConfig}
      highContrastCSS={window.ENV?.url_for_high_contrast_tinymce_editor_css}
      instRecordDisabled={window.ENV?.RICH_CONTENT_INST_RECORD_TAB_DISABLED}
      language={window.ENV?.LOCALE || 'en'}
      languages={languages}
      liveRegion={() => document.getElementById('flash_screenreader_holder')}
      ltiTools={window.INST?.editorButtons}
      mirroredAttrs={mirroredAttrs}
      readOnly={readOnly}
      textareaClassName={textareaClassName}
      textareaId={textareaId}
      height={height}
      trayProps={RCSProps}
      onFocus={onFocus}
      onBlur={onBlur}
      onContentChange={onContentChange}
      onInit={onInit}
      use_rce_pretty_html_editor={!!window.ENV?.FEATURES?.rce_pretty_html_editor}
      use_rce_buttons_and_icons={!!window.ENV?.FEATURES?.rce_buttons_and_icons}
      {...rest}
    />
  )
})

export default CanvasRce

CanvasRce.propTypes = {
  autosave: bool,
  defaultContent: string,
  editorOptions: object,
  height: oneOfType([number, string]),
  mirroredAttrs: objectOf(string),
  readOnly: bool,
  textareaClassName: string,
  textareaId: string.isRequired,
  onFocus: func, // f(RCEWrapper component) (sorry)
  onBlur: func, // f(event)
  onInit: func, // f(tinymce_editor)
  onContentChange: func // f(content), don't mistake this as an indication CanvasRce is a controlled component
}

CanvasRce.defaultProps = {
  autosave: true,
  mirroredAttrs: {},
  readOnly: false,
  textareaClassName: 'input-block-level',
  onFocus: () => {},
  onBlur: () => {},
  onContentChange: () => {},
  onInit: () => {}
}
