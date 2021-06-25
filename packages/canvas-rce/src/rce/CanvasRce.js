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
import {arrayOf, bool, func, number, object, objectOf, oneOfType, shape, string} from 'prop-types'
import formatMessage from '../format-message'
import RCEWrapper, {toolbarPropType, menuPropType, ltiToolsPropType} from './RCEWrapper'
import {trayPropTypes} from './plugins/shared/CanvasContentTray'
import editorLanguage from './editorLanguage'
import normalizeLocale from './normalizeLocale'
import wrapInitCb from './wrapInitCb'
import tinyRCE from './tinyRCE'
import defaultTinymceConfig from '../defaultTinymceConfig'
import getTranslations from '../getTranslations'
import '@instructure/canvas-theme'

if (!process?.env?.BUILD_LOCALE) {
  formatMessage.setup({
    locale: 'en',
    generateId: require('format-message-generate-id/underscored_crc32'),
    missingTranslation: 'ignore'
  })
}

// forward rceRef to it refs the RCEWrapper where clients can call getCode etc. on it.
const CanvasRce = forwardRef(function CanvasRce(props, rceRef) {
  const {
    autosave,
    defaultContent,
    editorOptions, // tinymce config
    height,
    highContrastCSS,
    instRecordDisabled,
    language,
    liveRegion,
    mirroredAttrs, // attributes to transfer from the original textarea to the one created by tinymce
    menu,
    plugins,
    readOnly,
    textareaId,
    textareaClassName,
    trayProps,
    toolbar,
    use_rce_pretty_html_editor,
    use_rce_buttons_and_icons,
    onFocus,
    onBlur,
    onInit,
    onContentChange,
    ...rest
  } = props

  useState(() => formatMessage.setup({locale: normalizeLocale(props.language)}))
  const [translations, setTranslations] = useState(() => {
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
  }, [])

  // some properties are only used on initialization
  // Languages is a bit of a mess. Tinymce and Canvas
  // have 2 different sets of language names. normalizeLocale
  // takes the language prop and returns the locale Canvas knows,
  // editorLanguage takes the language prop and returns the
  // corresponding locale for tinymce.
  const [initOnlyProps] = useState(() => {
    const iProps = {
      autosave,
      defaultContent,
      highContrastCSS,
      instRecordDisabled,
      language: normalizeLocale(language),
      liveRegion,
      menu,
      plugins,
      textareaId,
      textareaClassName,
      trayProps,
      toolbar,
      use_rce_pretty_html_editor,
      use_rce_buttons_and_icons,
      editorOptions: Object.assign(editorOptions, editorOptions, {
        selector: `#${textareaId}`,
        height,
        language: editorLanguage(props.language),
        toolbar: props.toolbar,
        menu: props.menu,
        menubar: props.menu ? Object.keys(props.menu).join(' ') : undefined,
        plugins: props.plugins,
        readonly: readOnly
      })
    }
    wrapInitCb(mirroredAttrs, iProps.editorOptions)

    return iProps
  })

  if (typeof translations !== 'boolean') {
    return formatMessage('Loading...')
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

export default CanvasRce

CanvasRce.propTypes = {
  autosave: shape({enabled: bool, maxAge: number}),
  defaultContent: string,
  editorOptions: object, // tinymce config
  height: oneOfType([number, string]),
  highContrastCSS: arrayOf(string),
  instRecordDisabled: bool,
  language: string,
  liveRegion: func,
  ltiTools: ltiToolsPropType,
  mirroredAttrs: objectOf(string), // attributes to transfer from the original textarea to the one created by tinymce
  menu: menuPropType,
  plugins: arrayOf(string),
  readOnly: bool,
  textareaId: string.isRequired,
  textareaClassName: string,
  trayProps: trayPropTypes,
  toolbar: toolbarPropType,
  use_rce_pretty_html_editor: bool,
  use_rce_buttons_and_icons: bool,
  onFocus: func, // f(RCEWrapper component)
  onBlur: func, // f(event)
  onInit: func, // f(tinymce_editor)
  onContentChange: func // f(content), don't mistake this as an indication CanvasRce is a controlled component
}

CanvasRce.defaultProps = {
  autosave: {enabled: false, maxAge: 3600000},
  defaultContent: '',
  editorOptions: {...defaultTinymceConfig},
  highContrastCSS: [],
  instRecordDisabled: false,
  language: 'en',
  liveRegion: () => document.getElementById('flash_screenreader_holder'),
  mirroredAttrs: {},
  readOnly: false,
  use_rce_pretty_html_editor: true,
  use_rce_buttons_and_icons: true,
  onFocus: () => {},
  onBlur: () => {},
  onContentChange: () => {},
  onInit: () => {}
}
