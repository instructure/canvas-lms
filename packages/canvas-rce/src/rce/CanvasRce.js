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
import {arrayOf, func, number, string} from 'prop-types'
import formatMessage from '../format-message'
import RCEWrapper, {toolbarPropType, menuPropType} from './RCEWrapper'
import {trayPropTypes} from './plugins/shared/CanvasContentTray'
import editorLanguage from './editorLanguage'
import normalizeLocale from './normalizeLocale'
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

const baseProps = {
  autosave: {enabled: false},
  defaultContent: '',
  // handleUnmount: () => {},
  instRecordDisabled: false,
  language: 'en',
  // languages: [],
  liveRegion: () => document.getElementById('flash_screenreader_holder'),
  mirroredAttrs: {name: 'message'}, // ???
  // onBlur: () => {},
  // onFous: () => {},
  textareaClassName: 'input-block-level',
  // textareaId: 'textarea2',
  // trayProps: {
  //   canUploadFiles: false,
  //   containingContext: {contextType: 'course', contextId: '1', userId: '1'},
  //   contextId: '1',
  //   contextType: 'course',
  //   filesTabDisabled: true,
  //   host: 'localhost:3001', // RCS
  //   jwt: 'this is not for real', // RCE
  //   refreshToken: () => {},
  //   themeUrl: undefined // "/dist/brandable_css/default/variables-8391c84da435c9cfceea2b2b3317ff66.json"
  // },
  highContrastCSS: [],
  use_rce_pretty_html_editor: true,
  use_rce_buttons_and_icons: true,
  editorOptions: {...defaultTinymceConfig}
}

function addCanvasConnection(propsOut, propsIn) {
  if (propsIn.trayProps) {
    propsOut.trayProps = propsIn.trayProps
  }
}

// forward rceRef to it refs the RCEWrapper where clients can call getCode etc. on it.
const CanvasRce = forwardRef((props, rceRef) => {
  const {
    defaultContent,
    textareaId,
    height,
    language,
    highContrastCSS,
    trayProps,
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

  // merge CanvasRce props into the base properties
  // Note: languages is a bit of a mess. Tinymce and Canvas
  // have 2 different sets of language names. normalizeLocale
  // takes the lanbuage prop and returns the locale Canvas knows.
  // editorLanguage takes the language prop and returns the
  // corresponding name for tinymce.
  const [wrapperProps] = useState(() => {
    const rceProps = {...baseProps}
    rceProps.language = normalizeLocale(props.language || 'en')
    rceProps.highContrastCSS = highContrastCSS || []
    rceProps.defaultContent = defaultContent
    rceProps.textareaId = textareaId
    rceProps.onContentChange = onContentChange
    rceProps.editorOptions.selector = `#${textareaId}`
    rceProps.editorOptions.height = height
    rceProps.editorOptions.language = editorLanguage(props.language || 'en')
    rceProps.editorOptions.toolbar = props.toolbar
    rceProps.editorOptions.menu = props.menu
    rceProps.editorOptions.menubar = props.menu ? Object.keys(props.menu).join(' ') : undefined
    rceProps.editorOptions.plugins = props.plugins
    rceProps.trayProps = trayProps

    addCanvasConnection(rceProps, props)

    return rceProps
  }, [])

  if (typeof translations !== 'boolean') {
    return formatMessage('Loading...')
  } else {
    return <RCEWrapper ref={rceRef} tinymce={tinyRCE} {...wrapperProps} {...rest} />
  }
})

export default CanvasRce

CanvasRce.propTypes = {
  language: string,
  defaultContent: string,
  textareaId: string.isRequired,
  height: number,
  highContrastCSS: arrayOf(string),
  trayProps: trayPropTypes,
  toolbar: toolbarPropType,
  menu: menuPropType,
  plugins: arrayOf(string),

  onInitted: func, // f(tinymce_editor)
  onContentChange: func // don't mistake this as an indication CanvasRce is a controlled component
}
