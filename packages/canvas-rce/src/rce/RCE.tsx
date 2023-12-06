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

import React, {forwardRef, useState} from 'react'
import formatMessage from '../format-message'
import RCEWrapper from './RCEWrapper'
import {EditorOptionsPropType, type ExternalToolsConfig, LtiToolsPropType} from './RCEWrapperProps'
import editorLanguage from './editorLanguage'
import normalizeLocale from './normalizeLocale'
import wrapInitCb from './wrapInitCb'
import tinyRCE from './tinyRCE'
import getTranslations from '../getTranslations'
import '@instructure/canvas-theme'
import {Editor} from 'tinymce'

if (!process || !process.env || !process.env.BUILD_LOCALE) {
  formatMessage.setup({
    locale: 'en',
    generateId: require('format-message-generate-id/underscored_crc32'),
    missingTranslation: 'ignore',
  })
}

// forward rceRef to it refs the RCEWrapper where clients can call getCode etc. on it.
// You probably shouldn't use it until onInit has been called. Until then tinymce
// is not initialized.
const RCE = forwardRef<RCEWrapper, RCEPropTypes>(function RCE(props, rceRef) {
  const {
    autosave,
    canvasOrigin,
    defaultContent,
    editorOptions, // tinymce config
    height,
    highContrastCSS,
    instRecordDisabled,
    language,
    liveRegion,
    mirroredAttrs, // attributes to transfer from the original textarea to the one created by tinymce
    readOnly,
    textareaId,
    textareaClassName,
    rcsProps,
    use_rce_icon_maker,
    features,
    onFocus,
    onBlur,
    onInit,
    onContentChange,
    ...rest
  } = props

  useState(() => {
    formatMessage.setup({locale: normalizeLocale(props.language)})
  })
  const [translations, setTranslations] = useState<Promise<void> | boolean>(() => {
    const locale = normalizeLocale(props.language)
    const p = getTranslations(locale)
      .then(() => {
        setTranslations(true)
      })
      .catch(err => {
        // eslint-disable-next-line no-console
        console.error('Failed loading the language file for', locale, '\n Cause:', err)
        setTranslations(false)
      })
    return p
  })

  // some properties are only used on initialization
  // Languages are a bit of a mess since Tinymce and Canvas
  // have 2 different sets of language names. normalizeLocale
  // takes the language prop and returns the locale Canvas knows,
  // editorLanguage takes the language prop and returns the
  // corresponding locale for tinymce.
  const [initOnlyProps] = useState(() => {
    const iProps = {
      autosave,
      canvasOrigin,
      defaultContent,
      highContrastCSS,
      instRecordDisabled,
      language: normalizeLocale(language),
      liveRegion,
      textareaId,
      textareaClassName,
      trayProps: rcsProps,
      use_rce_icon_maker,
      features,
      editorOptions: {
        ...editorOptions,
        selector: editorOptions?.selector || `#${textareaId}`,
        height,
        language: editorLanguage(props.language),
      },
    }
    wrapInitCb(mirroredAttrs, iProps.editorOptions)

    return iProps
  })

  if (typeof translations !== 'boolean') {
    return <>{formatMessage('Loading...')}</>
  } else {
    return (
      <RCEWrapper
        ref={rceRef}
        tinymce={tinyRCE}
        readOnly={readOnly}
        {...initOnlyProps}
        onFocus={onFocus}
        onBlur={onBlur}
        onContentChange={onContentChange}
        onInitted={onInit}
        {...rest}
      />
    )
  }
})

export interface RCEPropTypes {
  /**
   * do you want the rce to autosave content to localStorage, and
   * how long should it be until it's deleted.
   * If autosave is enabled, call yourRef.RCEClosed() if the user
   * exits the page normally (e.g. via Cancel or Save)
   */
  autosave?: {
    enabled?: boolean
    maxAge?: number
    interval?: number
  }

  /**
   * the protocol://domain:port for this RCE's canvas
   */
  canvasOrigin?: string

  /**
   * the initial content
   */
  defaultContent?: string

  /**
   * tinymce configuration. See defaultTinymceConfig for all the defaults
   * and RCEWrapper.editorOptionsPropType for stuff you may want to include
   */
  editorOptions?: EditorOptionsPropType

  /**
   * there's an open bug when RCE is rendered in a Modal form
   * and the user navigates to the KB Shortcut Helper Button using
   * Apple VoiceOver navigation keys (VO+arrows)
   * as a workaround, the KB Shortcut Helper Button may be supressed
   * setting renderKBShortcutModal to false
   */
  renderKBShortcutModal?: boolean

  /**
   * height of the RCE. if a number, in px
   */
  height?: number | string

  /**
   * array of URLs to high-contrast css
   */
  highContrastCSS?: string[]

  /**
   * if true, do not load the plugin that provides the media toolbar and menu items
   */
  instRecordDisabled?: boolean

  /**
   * locale of the user's language
   */
  language?: string

  /**
   * function that returns the element where screenreader alerts go
   */
  liveRegion?: () => HTMLElement | null | undefined

  /**
   * array of lti tools available to the user
   * {id, favorite} are all that's required, ther fields are ignored
   */
  ltiTools?: LtiToolsPropType

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
  mirroredAttrs?: {[key: string]: string}

  /**
   * is this RCE readonly?
   */
  readOnly?: boolean

  /**
   * id put on the generated textarea
   */
  textareaId: string

  /**
   * class name added to the generated textarea
   */
  textareaClassName?: string

  /**
   * properties necessary for the RCE to us the RCS
   * if missing, RCE features that require the RCS are omitted
   */
  rcsProps?: {
    canUploadFiles: boolean
    contextId: string
    contextType: string
    containingContext?: {
      contextType: string
      contextId: string
      userId: string
    }
    filesTabDisabled?: boolean
    host?: (props: any, propName: any, componentName: any) => void
    jwt?: (props: any, propName: any, componentName: any) => void
    refreshToken?: () => void
    source?: {
      fetchImages: () => void
    }
    themeUrl?: string
  }

  /**
   * enable the custom icon maker feature (temporary until the feature is forced on)
   */
  use_rce_icon_maker?: boolean

  /**
   * record of feature statuses from containing page
   */
  features?: {[key: string]: boolean}

  /**
   * configurable default timeout value for flash alerts
   */
  flashAlertTimeout?: number

  /**
   * user's timezone
   */
  timezone?: string

  /**
   * user's cache key to be used to encrypt and decrypt autosaved content
   */
  userCacheKey?: string

  onFocus?: (rce: RCEWrapper) => void
  onBlur?: (event: Event) => void
  onInit?: (editor: Editor) => void
  onContentChange?: (content: string) => void

  externalToolsConfig?: ExternalToolsConfig
}

const defaultProps = {
  autosave: {enabled: false, maxAge: 3600000},
  defaultContent: '',
  editorOptions: {},
  renderKBShortcutModal: true,
  highContrastCSS: [],
  instRecordDisabled: false,
  language: 'en',
  liveRegion: () => document.getElementById('flash_screenreader_holder'),
  maxInitRenderedRCEs: -1,
  mirroredAttrs: {},
  readOnly: false,
  use_rce_icon_maker: true,
  onFocus: () => undefined,
  onBlur: () => undefined,
  onContentChange: () => undefined,
  onInit: () => undefined,
}

RCE.defaultProps = defaultProps

export default RCE
