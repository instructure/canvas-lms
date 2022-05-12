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

import React, {forwardRef, useCallback, useEffect, useState} from 'react'
import {bool, func, number, object, objectOf, oneOfType, string} from 'prop-types'
import {createChainedFunction} from '@instructure/ui-utils'
import RCE from '@instructure/canvas-rce/es/rce/RCE'
import getRCSProps from '../getRCSProps'
import closedCaptionLanguages from '@canvas/util/closedCaptionLanguages'
import EditorConfig from '../tinymce.config'
import loadEventListeners from '../loadEventListeners'
import shouldUseFeature, {Feature} from '../shouldUseFeature'

// the ref you add via <CanvasRce ref={yourRef} /> will be a reference
// to the underlying RCEWrapper. You probably shouldn't use it until
// onInit has been called. Until then tinymce is not initialized.
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
    if (editorOptions.init_instance_callback) {
      config.init_instance_callback = createChainedFunction(
        config.init_instance_callback,
        editorOptions.init_instance_callback
      )
    }
    return config
  })
  const [autosave_] = useState({
    enabled: true,
    interval: Number.isNaN(ENV.rce_auto_save_max_age_ms) ? 3600000 : ENV.rce_auto_save_max_age_ms
  })
  const [refCreated, setRefCreated] = useState(null)

  // you have to use a callback function ref because a ref as a useEffect dependency
  // will never trigger it to be rerun. This way any time the ref changes,
  // the function is called. rceRef as a dependency is to quiet eslint.
  const magicRef = useCallback(
    node => {
      rceRef.current = node
      if (node) {
        node.getTextarea().remoteEditor = node
      }
      setRefCreated(node)
    },
    [rceRef]
  )

  useEffect(() => {
    const rce_wrapper = refCreated && rceRef.current
    return () => {
      rce_wrapper?.destroy()
    }
  }, [rceRef, refCreated])

  useEffect(() => {
    loadEventListeners()
  }, [])

  return (
    <RCE
      ref={magicRef}
      autosave={autosave_}
      defaultContent={defaultContent}
      editorOptions={tinymceConfig}
      highContrastCSS={window.ENV?.url_for_high_contrast_tinymce_editor_css}
      instRecordDisabled={window.ENV?.RICH_CONTENT_INST_RECORD_TAB_DISABLED}
      language={window.ENV?.LOCALE || 'en'}
      languages={languages}
      liveRegion={() => document.getElementById('flash_screenreader_holder')}
      ltiTools={window.INST?.editorButtons}
      maxInitRenderedRCEs={props.maxInitRenderedRCEs}
      mirroredAttrs={mirroredAttrs}
      readOnly={readOnly}
      textareaClassName={textareaClassName}
      textareaId={textareaId}
      height={height}
      rcsProps={RCSProps}
      onFocus={onFocus}
      onBlur={onBlur}
      onContentChange={onContentChange}
      onInit={onInit}
      use_rce_icon_maker={shouldUseFeature(Feature.IconMaker, window.ENV)}
      {...rest}
    />
  )
})

export default CanvasRce

CanvasRce.propTypes = {
  // should the RCE autosave content to localStorage as the user types
  autosave: bool,
  // the initial content
  defaultContent: string,
  // tinymce configuration overrides
  // see RCEWrapper's editorOptionsPropType for details.
  editorOptions: object,
  // height of the RCE. If a number, in px
  height: oneOfType([number, string]),
  // The maximum number of RCEs that will render on page load.
  // Any more than this will be deferred until it is nearly
  // scrolled into view.
  // if isNaN or <=0, render them all
  maxInitRenderedRCEs: number,
  // name:value pairs of attributes to add to the textarea
  // tinymce creates as the backing store of the RCE
  mirroredAttrs: objectOf(string),
  // is thie RCE readonly?
  readOnly: bool,
  // class name added to the generated textarea
  textareaClassName: string,
  // id of the generated textarea
  textareaId: string.isRequired,
  // event handlers
  onFocus: func, // f(RCEWrapper component) (sorry)
  onBlur: func, // f(event)
  onInit: func, // f(tinymce_editor)
  onContentChange: func // f(content), don't mistake this as an indication CanvasRce is a controlled component
}

CanvasRce.defaultProps = {
  autosave: true,
  editorOptions: {},
  maxInitRenderedRCEs: -1,
  mirroredAttrs: {},
  readOnly: false,
  textareaClassName: 'input-block-level',
  onFocus: () => {},
  onBlur: () => {},
  onContentChange: () => {},
  onInit: () => {}
}
