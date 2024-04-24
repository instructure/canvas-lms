// @ts-nocheck

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

import $ from 'jquery'

import React, {forwardRef, MutableRefObject, useCallback, useEffect, useState} from 'react'
import {createChainedFunction} from '@instructure/ui-utils'
import RCE, {RCEPropTypes} from '@instructure/canvas-rce/es/rce/RCE'
import RCEWrapper from '@instructure/canvas-rce/es/rce/RCEWrapper'
import getRCSProps from '../getRCSProps'
import EditorConfig from '../tinymce.config'
import loadEventListeners from '../loadEventListeners'
import shouldUseFeature, {Feature} from '../shouldUseFeature'
import tinymce, {Editor} from 'tinymce'
import {EditorOptionsPropType} from '@instructure/canvas-rce/es/rce/RCEWrapperProps'

// the ref you add via <CanvasRce ref={yourRef} /> will be a reference
// to the underlying RCEWrapper. You probably shouldn't use it until
// onInit has been called. Until then tinymce is not initialized.
const CanvasRce = forwardRef(function CanvasRce(
  props: CanvasRcePropTypes,
  _rceRef: React.ForwardedRef<RCEWrapper>
) {
  const rceRef = _rceRef as MutableRefObject<RCEWrapper>

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
    resourceType,
    resourceId,
    ...rest
  } = props

  const [RCSProps] = useState(getRCSProps())
  const [tinymceConfig] = useState(() => {
    // tinymce is a global by now via import of CanvasRce importing tinyRCE
    const editorConfig = new EditorConfig(tinymce, window.INST, textareaId)
    const config = {...editorConfig.defaultConfig(), ...editorOptions}
    if (editorOptions?.init_instance_callback) {
      config.init_instance_callback = createChainedFunction(
        config.init_instance_callback,
        editorOptions?.init_instance_callback
      )
    }
    return config
  })
  const [autosave_] = useState<RCEPropTypes['autosave']>({
    enabled: props.autosave,
    interval: Number.isNaN(ENV.rce_auto_save_max_age_ms) ? 3600000 : ENV.rce_auto_save_max_age_ms,
  })
  const [refCreated, setRefCreated] = useState<Element | null>(null)

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
    const rce_wrapper: RCEWrapper | null = refCreated && rceRef.current
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
      canvasOrigin={ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN || window.location?.origin || ''}
      defaultContent={defaultContent}
      editorOptions={tinymceConfig}
      highContrastCSS={
        window.ENV?.url_for_high_contrast_tinymce_editor_css
          ? [window.ENV?.url_for_high_contrast_tinymce_editor_css]
          : []
      }
      instRecordDisabled={window.ENV?.RICH_CONTENT_INST_RECORD_TAB_DISABLED}
      language={window.ENV?.LOCALES?.[0] || 'en'}
      userCacheKey={window.ENV?.user_cache_key}
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
      resourceType={resourceType}
      resourceId={resourceId}
      externalToolsConfig={{
        ltiIframeAllowances: window.ENV?.LTI_LAUNCH_FRAME_ALLOWANCES,
        isA2StudentView: window.ENV?.a2_student_view,
        maxMruTools: window.ENV?.MAX_MRU_LTI_TOOLS,
        resourceSelectionUrlOverride:
          $('#context_external_tool_resource_selection_url').attr('href') || null,
      }}
      {...rest}
    />
  )
})

export interface CanvasRcePropTypes {
  /**
   * should the RCE autosave content to localStorage as the user types
   */
  autosave?: boolean

  /**
   * the initial content
   */
  defaultContent?: string

  /**
   * tinymce configuration overrides
   * see RCEWrapper's editorOptionsPropType for details.
   */
  editorOptions?: EditorOptionsPropType

  /**
   * height of the RCE. If a number, in px
   */
  height?: number | string

  /**
   * The maximum number of RCEs that will render on page load.
   * Any more than this will be deferred until it is nearly
   * scrolled into view.
   * if isNaN or <=0, render them all
   */
  maxInitRenderedRCEs?: number

  /**
   * name:value pairs of attributes to add to the textarea
   * tinymce creates as the backing store of the RCE
   */
  mirroredAttrs?: Record<string, string>

  /**
   * is thie RCE readonly?
   */
  readOnly?: boolean

  /**
   * class name added to the generated textarea
   */
  textareaClassName?: string

  /**
   * id of the generated textarea
   */
  textareaId: string

  /**
   * object of 'featureName': bool key/value pairs
   */
  features?: Record<string, boolean>

  /**
   * configurable default timeout value for flash alerts
   */
  flashAlertTimeout?: number
  /**
   * user's timezone
   */
  timezone?: string

  onFocus?: (rceWrapper: RCEWrapper) => void
  onBlur?: (event: Event) => void
  onInit?: (tinymce_editor: Editor) => void

  /**
   * Don't mistake this as an indication CanvasRce is a controlled component
   */
  onContentChange?: (content: string) => void

  /**
   * type of the resource where the RCE is used (i.e., 'discussion_topic')
   */
  resourceType?: string

  /**
   * id of the resource where the RCE is used
   */
  resourceId?: number
}

const defaultProps: Partial<CanvasRcePropTypes> = {
  autosave: true,
  editorOptions: {},
  maxInitRenderedRCEs: -1,
  mirroredAttrs: {},
  readOnly: false,
  textareaClassName: 'input-block-level',
  features: ENV?.FEATURES || {},
  flashAlertTimeout: ENV?.flashAlertTimeout || 10000,
  timezone: ENV?.TIMEZONE,
  onFocus: () => {},
  onBlur: () => {},
  onContentChange: () => {},
  onInit: () => {},
}

CanvasRce.defaultProps = defaultProps

export default CanvasRce
