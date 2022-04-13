/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import React, {Suspense} from 'react'
import {Editor} from '@tinymce/tinymce-react'
import _ from 'lodash'

import themeable from '@instructure/ui-themeable'
import {IconKeyboardShortcutsLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {debounce} from '@instructure/debounce'
import getCookie from '../common/getCookie'

import formatMessage from '../format-message'
import * as contentInsertion from './contentInsertion'
import indicatorRegion from './indicatorRegion'
import editorLanguage from './editorLanguage'
import normalizeLocale from './normalizeLocale'
import {sanitizePlugins} from './sanitizePlugins'
import {getCanvasUrl} from './getCanvasUrl'

import indicate from '../common/indicate'
import bridge from '../bridge'
import CanvasContentTray, {trayPropTypes} from './plugins/shared/CanvasContentTray'
import StatusBar, {WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW} from './StatusBar'
import {VIEW_CHANGE} from './customEvents'
import ShowOnFocusButton from './ShowOnFocusButton'
import theme from '../skins/theme'
import {isAudio, isImage, isVideo} from './plugins/shared/fileTypeUtils'
import KeyboardShortcutModal from './KeyboardShortcutModal'
import AlertMessageArea from './AlertMessageArea'
import alertHandler from './alertHandler'
import {isFileLink, isImageEmbed} from './plugins/shared/ContentSelection'
import {
  VIDEO_SIZE_DEFAULT,
  AUDIO_PLAYER_SIZE
} from './plugins/instructure_record/VideoOptionsTray/TrayController'

const RestoreAutoSaveModal = React.lazy(() => import('./RestoreAutoSaveModal'))
const RceHtmlEditor = React.lazy(() => import('./RceHtmlEditor'))

const ASYNC_FOCUS_TIMEOUT = 250
const DEFAULT_RCE_HEIGHT = '400px'

const toolbarPropType = PropTypes.arrayOf(
  PropTypes.shape({
    // name of the toolbar the items are added to
    // if this toolbar doesn't exist, it is created
    // tinymce toolbar config does not
    // include a key to identify the individual toolbars, just a name
    // which is translated. This toolbar's name must be translated
    // in order to be merged correctly.
    name: PropTypes.string.isRequired,
    // items added to the toolbar
    // each is the name of the button some plugin has
    // registered with tinymce
    items: PropTypes.arrayOf(PropTypes.string).isRequired
  })
)

const menuPropType = PropTypes.objectOf(
  // the key is the name of the menu item a plugin has
  // registered with tinymce. If it does not exist in the
  // default menubar, it will be added.
  PropTypes.shape({
    // if this is a new menu in the menubar, title is it's label.
    // if these are items being merged into an existing menu, title is ignored
    title: PropTypes.string,
    // items is a space separated list it menu_items
    // some plugin has registered with tinymce
    items: PropTypes.string.isRequired
  })
)
const ltiToolsPropType = PropTypes.arrayOf(
  PropTypes.shape({
    // id of the tool
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    // is this a favorite tool?
    favorite: PropTypes.bool
  })
)

export const editorOptionsPropType = PropTypes.shape({
  // height of the RCE.
  // if a number interpreted as pixels.
  // if a string as a CSS value.
  height: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  // entries you want merged into the toolbar. See toolBarPropType above.
  toolbar: toolbarPropType,
  // entries you want merged into to the menus. See menuPropType above.
  // If an entry defines a new menu, tinymce's menubar config option will
  // be updated for you. In fact, if you provide an editorOptions.menubar value
  // it will be overwritten.
  menu: menuPropType,
  // additional plugins that get merged into the default list of plugins
  // it is up to you to import the plugin's definition which will
  // register it and any related toolbar or menu entries with tinymce.
  plugins: PropTypes.arrayOf(PropTypes.string),
  // is this RCE readonly?
  readonly: PropTypes.bool
})

// we  `require` instead of `import` because the ui-themeable babel require hook only works with `require`
// 2021-04-21: This is no longer true, but I didn't want to make a gratutious change when I found this out.
// see https://gerrit.instructure.com/c/canvas-lms/+/263299/2/packages/canvas-rce/src/rce/RCEWrapper.js#50
// for an `import` style solution
const styles = require('../skins/skin-delta.css')
const skinCSS = require('../../node_modules/tinymce/skins/ui/oxide/skin.min.css')
  .template()
  .replace(/tinymce__oxide--/g, '')
const contentCSS = require('../../node_modules/tinymce/skins/ui/oxide/content.css')
  .template()
  .replace(/tinymce__oxide--/g, '')

// If we ever get our jest tests configured so they can handle importing real esModules,
// we can move this to plugins/instructure-ui-icons/plugin.js like the rest.
function addKebabIcon(editor) {
  editor.ui.registry.addIcon(
    'more-drawer',
    `
    <svg viewBox="0 0 1920 1920">
      <path d="M1129.412 1637.647c0 93.448-75.964 169.412-169.412 169.412-93.448 0-169.412-75.964-169.412-169.412 0-93.447 75.964-169.412 169.412-169.412 93.448 0 169.412 75.965 169.412 169.412zm0-677.647c0 93.448-75.964 169.412-169.412 169.412-93.448 0-169.412-75.964-169.412-169.412 0-93.448 75.964-169.412 169.412-169.412 93.448 0 169.412 75.964 169.412 169.412zm0-677.647c0 93.447-75.964 169.412-169.412 169.412-93.448 0-169.412-75.965-169.412-169.412 0-93.448 75.964-169.412 169.412-169.412 93.448 0 169.412 75.964 169.412 169.412z" stroke="none" stroke-width="1" fill-rule="evenodd"/>
    </svg>
  `
  )
}

// Get oxide the default skin injected into the DOM before the overrides loaded by themeable
let inserted = false
function injectTinySkin() {
  if (inserted) return
  inserted = true
  const style = document.createElement('style')
  style.setAttribute('data-skin', 'tiny oxide skin')
  style.appendChild(
    // the .replace here is because the ui-themeable babel hook adds that prefix to all the class names
    document.createTextNode(skinCSS)
  )
  const beforeMe =
    document.head.querySelector('style[data-glamor]') || // find instui's themeable stylesheet
    document.head.querySelector('style') || // find any stylesheet
    document.head.firstElementChild
  document.head.insertBefore(style, beforeMe)
}

const editorWrappers = new WeakMap()

function focusToolbar(el) {
  const $firstToolbarButton = el.querySelector('.tox-tbtn')
  $firstToolbarButton && $firstToolbarButton.focus()
}

function focusFirstMenuButton(el) {
  const $firstMenu = el.querySelector('.tox-mbtn')
  $firstMenu && $firstMenu.focus()
}

function isElementWithinTable(node) {
  let elem = node
  while (elem) {
    if (elem.tagName === 'TABLE' || elem.tagName === 'TD' || elem.tagName === 'TH') {
      return true
    }
    elem = elem.parentElement
  }
  return false
}

// determines if localStorage is available for our use.
// see https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API
export function storageAvailable() {
  let storage
  try {
    storage = window.localStorage
    const x = '__storage_test__'
    storage.setItem(x, x)
    storage.removeItem(x)
    return true
  } catch (e) {
    return (
      e instanceof DOMException &&
      // everything except Firefox
      (e.code === 22 ||
        // Firefox
        e.code === 1014 ||
        // test name field too, because code might not be present
        // everything except Firefox
        e.name === 'QuotaExceededError' ||
        // Firefox
        e.name === 'NS_ERROR_DOM_QUOTA_REACHED') &&
      // acknowledge QuotaExceededError only if there's something already stored
      storage &&
      storage.length !== 0
    )
  }
}

function getHtmlEditorCookie() {
  const value = getCookie('rce.htmleditor')
  return value === RAW_HTML_EDITOR_VIEW || value === PRETTY_HTML_EDITOR_VIEW
    ? value
    : PRETTY_HTML_EDITOR_VIEW
}

function renderLoading() {
  return formatMessage('Loading')
}

// safari implements only the webkit prefixed version of the fullscreen api
const FS_ELEMENT =
  document.fullscreenElement === undefined ? 'webkitFullscreenElement' : 'fullscreenElement'
const FS_REQUEST = document.body.requestFullscreen ? 'requestFullscreen' : 'webkitRequestFullscreen'
const FS_EXIT = document.exitFullscreen ? 'exitFullscreen' : 'webkitExitFullscreen'

let alertIdValue = 0

@themeable(theme, styles)
class RCEWrapper extends React.Component {
  static getByEditor(editor) {
    return editorWrappers.get(editor)
  }

  static propTypes = {
    autosave: PropTypes.shape({
      enabled: PropTypes.bool,
      maxAge: PropTypes.number
    }),
    defaultContent: PropTypes.string,
    editorOptions: editorOptionsPropType,
    handleUnmount: PropTypes.func,
    editorView: PropTypes.oneOf([WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW]),
    renderKBShortcutModal: PropTypes.bool,
    id: PropTypes.string,
    language: PropTypes.string,
    liveRegion: PropTypes.func.isRequired,
    ltiTools: ltiToolsPropType,
    onContentChange: PropTypes.func,
    onFocus: PropTypes.func,
    onBlur: PropTypes.func,
    onInitted: PropTypes.func,
    onRemove: PropTypes.func,
    textareaClassName: PropTypes.string,
    textareaId: PropTypes.string.isRequired,
    languages: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired
      })
    ),
    readOnly: PropTypes.bool,
    tinymce: PropTypes.object,
    trayProps: trayPropTypes,
    toolbar: toolbarPropType,
    menu: menuPropType,
    plugins: PropTypes.arrayOf(PropTypes.string),
    instRecordDisabled: PropTypes.bool,
    highContrastCSS: PropTypes.arrayOf(PropTypes.string),
    maxInitRenderedRCEs: PropTypes.number,
    use_rce_buttons_and_icons: PropTypes.bool
  }

  static defaultProps = {
    trayProps: null,
    languages: [{id: 'en', label: 'English'}],
    autosave: {enabled: false},
    highContrastCSS: [],
    ltiTools: [],
    maxInitRenderedRCEs: -1
  }

  static skinCssInjected = false

  constructor(props) {
    super(props)

    this.editor = null // my tinymce editor instance
    this.language = normalizeLocale(this.props.language)

    // interface consistent with editorBox
    this.get_code = this.getCode
    this.set_code = this.setCode
    this.insert_code = this.insertCode

    // test override points
    this.indicator = false

    this._elementRef = React.createRef()
    this._editorPlaceholderRef = React.createRef()
    this._prettyHtmlEditorRef = React.createRef()
    this._showOnFocusButton = null

    injectTinySkin()

    let ht = props.editorOptions?.height || DEFAULT_RCE_HEIGHT
    if (!Number.isNaN(ht)) {
      ht = `${ht}px`
    }

    const currentRCECount = document.querySelectorAll('.rce-wrapper').length
    const maxInitRenderedRCEs = Number.isNaN(props.maxInitRenderedRCEs)
      ? RCEWrapper.defaultProps.maxInitRenderedRCEs
      : props.maxInitRenderedRCEs

    this.state = {
      path: [],
      wordCount: 0,
      editorView: props.editorView || WYSIWYG_VIEW,
      shouldShowOnFocusButton:
        props.renderKBShortcutModal === undefined ? true : props.renderKBShortcutModal,
      KBShortcutModalOpen: false,
      messages: [],
      announcement: null,
      confirmAutoSave: false,
      autoSavedContent: '',
      id: this.props.id || this.props.textareaId || `${Date.now()}`,
      height: ht,
      fullscreenState: {
        headerDisp: 'static',
        isTinyFullscreen: false
      },
      a11yErrorsCount: 0,
      shouldShowEditor:
        typeof IntersectionObserver === 'undefined' ||
        maxInitRenderedRCEs <= 0 ||
        currentRCECount < maxInitRenderedRCEs
    }
    this.pendingEventHandlers = []

    // Get top 2 favorited LTI Tools
    this.ltiToolFavorites =
      this.props.ltiTools
        .filter(e => e.favorite)
        .map(e => `instructure_external_button_${e.id}`)
        .slice(0, 2) || []

    this.tinymceInitOptions = this.wrapOptions(props.editorOptions)

    alertHandler.alertFunc = this.addAlert

    this.handleContentTrayClosing = this.handleContentTrayClosing.bind(this)

    this.a11yCheckerReady = import('./initA11yChecker')
      .then(initA11yChecker => {
        initA11yChecker.default(this.language)
        this.checkAccessibility()
      })
      .catch(err => {
        // eslint-disable-next-line no-console
        console.error('Failed initializing a11y checker', err)
      })
  }

  getCanvasUrl() {
    if (!this.canvasUrl) this.canvasUrl = getCanvasUrl(this.props.trayProps)

    return this.canvasUrl.then(url => {
      if (!url) {
        console.warn(
          'Could not determine Canvas base URL.',
          'Content will be referenced by relative URL.'
        )
      }
      return url
    })
  }

  // getCode and setCode naming comes from tinyMCE
  // kind of strange but want to be consistent
  getCode() {
    return this.isHidden() ? this.textareaValue() : this.mceInstance().getContent()
  }

  checkReadyToGetCode(promptFunc) {
    let status = true
    // Check for remaining placeholders
    if (this.mceInstance().dom.doc.querySelector(`[data-placeholder-for]`)) {
      status = promptFunc(
        formatMessage(
          'Content is still being uploaded, if you continue it will not be embedded properly.'
        )
      )
    }

    return status
  }

  setCode(newContent) {
    this.mceInstance()?.setContent(newContent)
  }

  // This function is called imperatively by the page that renders the RCE.
  // It should be called when the RCE content is done being edited.
  RCEClosed() {
    // We want to clear the autosaved content, since the page was legitimately closed.
    if (this.storage) {
      this.storage.removeItem(this.autoSaveKey)
    }
  }

  indicateEditor(element) {
    if (document.querySelector('[role="dialog"][data-mce-component]')) {
      // there is a modal open, which zeros out the vertical scroll
      // so the indicator is in the wrong place.  Give it a chance to close
      window.setTimeout(() => {
        this.indicateEditor(element)
      }, 100)
      return
    }
    const editor = this.mceInstance()
    if (this.indicator) {
      this.indicator(editor, element)
    } else if (!this.isHidden()) {
      indicate(indicatorRegion(editor, element))
    }
  }

  contentInserted(element) {
    this.indicateEditor(element)
    this.checkImageLoadError(element)
    this.sizeEditorForContent(element)
  }

  // make a attempt at sizing the editor so that the new content fits.
  // works under the assumptions the body's box-sizing is not content-box
  // and that the content is w/in a <p> whose margin is 12px top and bottom
  // (which, in canvas, is set in app/stylesheets/components/_ic-typography.scss)
  sizeEditorForContent(elem) {
    let height
    if (elem && elem.nodeType === 1) {
      height = elem.clientHeight
    }
    if (height) {
      const ifr = this.iframe
      if (ifr) {
        const editor_body_style = ifr.contentWindow.getComputedStyle(
          this.iframe.contentDocument.body
        )
        const editor_ht =
          ifr.contentDocument.body.clientHeight -
          parseInt(editor_body_style['padding-top'], 10) -
          parseInt(editor_body_style['padding-bottom'], 10)

        const para_margin_ht = 24
        const reserve_ht = Math.ceil(height + para_margin_ht)
        if (reserve_ht > editor_ht) {
          this.onResize(null, {deltaY: reserve_ht - editor_ht})
        }
      }
    }
  }

  checkImageLoadError(element) {
    if (!element || element.tagName !== 'IMG') {
      return
    }
    if (!element.complete) {
      element.onload = () => this.checkImageLoadError(element)
      return
    }
    // checking naturalWidth in a future event loop run prevents a race
    // condition between the onload callback and naturalWidth being set.
    setTimeout(() => {
      if (element.naturalWidth === 0) {
        element.style.border = '1px solid #000'
        element.style.padding = '2px'
      }
    }, 0)
  }

  insertCode(code) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertContent(editor, code)
    this.contentInserted(element)
  }

  insertEmbedCode(code) {
    const editor = this.mceInstance()

    // don't replace selected text, but embed after
    editor.selection.collapse()

    // tinymce treats iframes uniquely, and doesn't like adding attributes
    // once it's in the editor, and I'd rather not parse the incomming html
    // string with a regex, so let's create a temp copy, then add a title
    // attribute if one doesn't exist. This will let screenreaders announce
    // that there's some embedded content helper
    // From what I've read, "title" is more reliable than "aria-label" for
    // elements like iframes and embeds.
    const temp = document.createElement('div')
    temp.innerHTML = code
    const code_elem = temp.firstElementChild
    if (code_elem) {
      if (!code_elem.hasAttribute('title') && !code_elem.hasAttribute('aria-label')) {
        code_elem.setAttribute('title', formatMessage('embedded content'))
      }
      code = code_elem.outerHTML
    }

    // inserting an iframe in tinymce (as is often the case with
    // embedded content) causes it to wrap it in a span
    // and it's often inserted into a <p> on top of that.  Find the
    // iframe and use it to flash the indicator.
    const element = contentInsertion.insertContent(editor, code)
    const ifr = element && element.querySelector && element.querySelector('iframe')
    if (ifr) {
      this.contentInserted(ifr)
    } else {
      this.contentInserted(element)
    }
  }

  insertImage(image) {
    const editor = this.mceInstance()
    let element = contentInsertion.insertImage(editor, image)

    // Removes TinyMCE's caret &nbsp; text if exists.
    if (element?.nextSibling?.data?.trim() === '') {
      element.nextSibling.remove()
    }

    if (element && element.complete) {
      this.contentInserted(element)
    } else if (element) {
      element.onload = () => this.contentInserted(element)
      element.onerror = () => this.checkImageLoadError(element)
    }
  }

  insertImagePlaceholder(fileMetaProps) {
    let width, height
    let align = 'middle'
    if (isImage(fileMetaProps.contentType) && fileMetaProps.displayAs !== 'link') {
      const image = new Image()
      image.src = fileMetaProps.domObject.preview
      width = image.width
      height = image.height
      // we constrain the <img> to max-width: 100%, so scale the size down if necessary
      const maxWidth = this.iframe.contentDocument.body.clientWidth
      if (width > maxWidth) {
        height = Math.round((maxWidth / width) * height)
        width = maxWidth
      }
      width = `${width}px`
      height = `${height}px`
    } else if (isVideo(fileMetaProps.contentType || fileMetaProps.type)) {
      width = VIDEO_SIZE_DEFAULT.width
      height = VIDEO_SIZE_DEFAULT.height
      align = 'bottom'
    } else if (isAudio(fileMetaProps.contentType || fileMetaProps.type)) {
      width = AUDIO_PLAYER_SIZE.width
      height = AUDIO_PLAYER_SIZE.height
      align = 'bottom'
    } else {
      width = `${fileMetaProps.name.length}rem`
      height = '1rem'
    }
    // if you're wondering, the &nbsp; scatter about in the svg
    // is because tinymce will strip empty elements
    const markup = `
    <span
      aria-label="${formatMessage('Loading')}"
      data-placeholder-for="${encodeURIComponent(fileMetaProps.name)}"
      style="width: ${width}; height: ${height}; vertical-align: ${align};"
    >
      <svg xmlns="http://www.w3.org/2000/svg" version="1.1" x="0px" y="0px" viewBox="0 0 100 100" height="100px" width="100px">
        <g style="stroke-width:.5rem;fill:none;stroke-linecap:round;">&nbsp;
          <circle class="c1" cx="50%" cy="50%" r="28px">&nbsp;</circle>
          <circle class="c2" cx="50%" cy="50%" r="28px">&nbsp;</circle>
          &nbsp;
        </g>
        &nbsp;
      </svg>
    </span>`

    const editor = this.mceInstance()
    editor.undoManager.ignore(() => {
      editor.execCommand('mceInsertContent', false, markup)
    })
  }

  insertVideo(video) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertVideo(editor, video)
    this.contentInserted(element)
  }

  insertAudio(audio) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertAudio(editor, audio)
    this.contentInserted(element)
  }

  insertMathEquation(tex) {
    const editor = this.mceInstance()
    return this.getCanvasUrl().then(domain => contentInsertion.insertEquation(editor, tex, domain))
  }

  removePlaceholders(name) {
    const placeholder = this.mceInstance().dom.doc.querySelector(
      `[data-placeholder-for="${encodeURIComponent(name)}"]`
    )
    if (placeholder) {
      const editor = this.mceInstance()
      editor.undoManager.ignore(() => {
        editor.dom.remove(placeholder)
      })
    }
  }

  insertLink(link) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertLink(editor, link)
    this.contentInserted(element)
  }

  existingContentToLink() {
    const editor = this.mceInstance()
    return contentInsertion.existingContentToLink(editor)
  }

  existingContentToLinkIsImg() {
    const editor = this.mceInstance()
    return contentInsertion.existingContentToLinkIsImg(editor)
  }

  // since we may defer rendering tinymce, queue up any tinymce event handlers
  tinymceOn(tinymceEventName, handler) {
    if (this.state.shouldShowEditor) {
      this.mceInstance().on(tinymceEventName, handler)
    } else {
      this.pendingEventHandlers.push({name: tinymceEventName, handler})
    }
  }

  mceInstance() {
    if (this.editor) {
      return this.editor
    }
    const editors = this.props.tinymce.editors || []
    return editors.filter(ed => ed.id === this.props.textareaId)[0]
  }

  onTinyMCEInstance(command, args) {
    const editor = this.mceInstance()
    if (editor) {
      if (command === 'mceRemoveEditor') {
        editor.execCommand('mceNewDocument')
      } // makes sure content can't persist past removal
      editor.execCommand(command, false, this.props.textareaId, args)
    }
  }

  destroy() {
    this._destroyCalled = true
    this.unhandleTextareaChange()
    this.props.handleUnmount && this.props.handleUnmount()
  }

  onRemove = () => {
    bridge.detachEditor(this)
    this.props.onRemove && this.props.onRemove(this)
  }

  getTextarea() {
    return document.getElementById(this.props.textareaId)
  }

  textareaValue() {
    return this.getTextarea().value
  }

  get id() {
    return this.state.id
  }

  toggleView = newView => {
    // coming from the menubar, we don't have a newView,

    const wasFullscreen = this._isFullscreen()
    if (wasFullscreen) this._exitFullscreen()
    let newState
    switch (this.state.editorView) {
      case WYSIWYG_VIEW:
        newState = {editorView: newView || PRETTY_HTML_EDITOR_VIEW}
        break
      case PRETTY_HTML_EDITOR_VIEW:
        newState = {editorView: newView || WYSIWYG_VIEW}
        break
      case RAW_HTML_EDITOR_VIEW:
        newState = {editorView: newView || WYSIWYG_VIEW}
    }
    this.setState(newState, () => {
      if (wasFullscreen) {
        window.setTimeout(() => {
          this._enterFullscreen()
        }, 200) // due to the animation it takes some time for fullscreen to complete
      }
    })
    this.checkAccessibility()
    if (newView === PRETTY_HTML_EDITOR_VIEW || newView === RAW_HTML_EDITOR_VIEW) {
      document.cookie = `rce.htmleditor=${newView};path=/;max-age=31536000`
    }

    // Emit view change event
    this.mceInstance().fire(VIEW_CHANGE, {target: this.editor, newView: newState.editorView})
  }

  _isFullscreen() {
    return this.state.fullscreenState.isTinyFullscreen || document[FS_ELEMENT]
  }

  _enterFullscreen() {
    switch (this.state.editorView) {
      case PRETTY_HTML_EDITOR_VIEW:
        this._prettyHtmlEditorRef.current.addEventListener(
          'fullscreenchange',
          this._toggleFullscreen
        )
        this._prettyHtmlEditorRef.current.addEventListener(
          'webkitfullscreenchange',
          this._toggleFullscreen
        )
        // if I don't focus first, FF complains that the element
        // is not in the active browser tab and requestFullscreen fails
        this._prettyHtmlEditorRef.current.focus()
        this._prettyHtmlEditorRef.current[FS_REQUEST]()
        break
      case RAW_HTML_EDITOR_VIEW:
        this.getTextarea().addEventListener('fullscreenchange', this._toggleFullscreen)
        this.getTextarea().addEventListener('webkitfullscreenchange', this._toggleFullscreen)
        this.getTextarea()[FS_REQUEST]()
        break
      case WYSIWYG_VIEW:
        this.mceInstance().execCommand('mceFullScreen')
        break
    }
  }

  _exitFullscreen() {
    if (this.state.fullscreenState.isTinyFullscreen) {
      this.mceInstance().execCommand('mceFullScreen')
    } else if (document[FS_ELEMENT]) {
      document[FS_ELEMENT][FS_EXIT]()
    }
  }

  focus() {
    this.onTinyMCEInstance('mceFocus')
    // tinymce doesn't always call the focus handler.
    this.handleFocusEditor(new Event('focus', {target: this.mceInstance()}))
  }

  focusCurrentView() {
    switch (this.state.editorView) {
      case WYSIWYG_VIEW:
        this.mceInstance().focus()
        break
      case PRETTY_HTML_EDITOR_VIEW:
        {
          const cmta = this._elementRef.current.querySelector('.CodeMirror textarea')
          if (cmta) {
            cmta.focus()
          } else {
            window.setTimeout(() => {
              this._elementRef.current.querySelector('.CodeMirror textarea')?.focus()
            }, 200)
          }
        }
        break
      case RAW_HTML_EDITOR_VIEW:
        this.getTextarea().focus()
        break
    }
  }

  is_dirty() {
    if (this.mceInstance().isDirty()) {
      return true
    }
    const content = this.isHidden() ? this.textareaValue() : this.mceInstance()?.getContent()
    return content !== this.cleanInitialContent()
  }

  cleanInitialContent() {
    if (!this._cleanInitialContent) {
      const el = window.document.createElement('div')
      el.innerHTML = this.props.defaultContent
      const serializer = this.mceInstance().serializer
      this._cleanInitialContent = serializer.serialize(el, {getInner: true})
    }
    return this._cleanInitialContent
  }

  isHtmlView() {
    return this.state.editorView !== WYSIWYG_VIEW
  }

  isHidden() {
    return this.mceInstance().isHidden()
  }

  get iframe() {
    return document.getElementById(`${this.props.textareaId}_ifr`)
  }

  // these focus and blur event handlers work together so that RCEWrapper
  // can report focus and blur events from the RCE at-large
  get focused() {
    return this === bridge.getEditor()
  }

  handleFocus(_event) {
    if (!this.focused) {
      bridge.focusEditor(this)
      this.props.onFocus && this.props.onFocus(this)
    }
  }

  contentTrayClosing = false

  handleContentTrayClosing(isClosing) {
    this.contentTrayClosing = isClosing
  }

  blurTimer = 0

  handleBlur(event) {
    if (this.blurTimer) return

    if (this.focused) {
      // because the old active element fires blur before the next element gets focus
      // we often need a moment to see if focus comes back
      event && event.persist && event.persist()
      this.blurTimer = window.setTimeout(() => {
        this.blurTimer = 0
        if (this.contentTrayClosing) {
          // the CanvasContentTray is in the process of closing
          // wait until it finishes
          return
        }

        if (this._elementRef.current?.contains(document.activeElement)) {
          // focus is still somewhere w/in me
          return
        }

        const activeClass = document.activeElement && document.activeElement.getAttribute('class')
        if (
          (event.focusedEditor === undefined || event.target.id === event.focusedEditor?.id) &&
          activeClass?.includes('tox-')
        ) {
          // if a toolbar button has focus, then the user clicks on the "more" button
          // focus jumps to the body, then eventually to the popped up toolbar. This
          // catches that case.
          return
        }

        if (event?.relatedTarget?.getAttribute('class')?.includes('tox-')) {
          // a tinymce popup has focus
          return
        }

        const popups = document.querySelectorAll('[data-mce-component]')
        for (const popup of popups) {
          if (popup.contains(document.activeElement)) {
            // one of our popups has focus
            return
          }
        }

        bridge.blurEditor(this)
        this.props.onBlur && this.props.onBlur(event)
      }, ASYNC_FOCUS_TIMEOUT)
    }
  }

  handleFocusRCE = event => {
    this.handleFocus(event)
  }

  handleBlurRCE = event => {
    if (event.relatedTarget === null) {
      // focus might be moving to tinymce
      this.handleBlur(event)
    }

    if (!this._elementRef.current?.contains(event.relatedTarget)) {
      this.handleBlur(event)
    }
  }

  handleFocusEditor = (event, _editor) => {
    // use .active to put a focus ring around the content area
    // when the editor has focus. This isn't perfect, but it's
    // what we've got for now.
    const ifr = this.iframe
    ifr && ifr.parentElement.classList.add('active')

    this._forceCloseFloatingToolbar()
    this.handleFocus(event)
  }

  handleFocusHtmlEditor = event => {
    this.handleFocus(event)
  }

  handleBlurEditor = (event, _editor) => {
    const ifr = this.iframe
    ifr && ifr.parentElement.classList.remove('active')
    this.handleBlur(event)
  }

  call(methodName, ...args) {
    // since exists? has a ? and cant be a regular function just return true
    // rather than calling as a fn on the editor
    if (methodName === 'exists?') {
      return true
    }
    return this[methodName](...args)
  }

  handleKey = event => {
    if (event.code === 'F9' && event.altKey) {
      event.preventDefault()
      event.stopPropagation()
      this.setFocusAbilityForHeader(true);
      focusFirstMenuButton(this._elementRef.current)
    } else if (event.code === 'F10' && event.altKey) {
      event.preventDefault()
      event.stopPropagation()
      this.setFocusAbilityForHeader(true);
      focusToolbar(this._elementRef.current)
    } else if ((event.code === 'F8' || event.code === 'Digit0') && event.altKey) {
      event.preventDefault()
      event.stopPropagation()
      this.openKBShortcutModal()
    } else if (event.code === 'Escape') {
      this._forceCloseFloatingToolbar()
      if (this.state.fullscreenState.isTinyFullscreen) {
        this.mceInstance().execCommand('mceFullScreen') // turn it off
      } else {
        bridge.hideTrays()
      }
    } else if (['n', 'N', 'd', 'D'].indexOf(event.key) !== -1) {
      // Prevent key events from bubbling up on touch screen device
      event.stopPropagation()
    }
  }

  handleClickFullscreen = () => {
    if (this._isFullscreen()) {
      this._exitFullscreen()
    } else {
      this._enterFullscreen()
    }
  }

  handleExternalClick = () => {
    this._forceCloseFloatingToolbar()
    debounce(this.checkAccessibility, 1000)()
  }

  handleInputChange = () => {
    this.checkAccessibility()
  }

  onInit = (_event, editor) => {
    editor.rceWrapper = this
    this.editor = editor
    const textarea = this.editor.getElement()

    // expected by canvas
    textarea.dataset.rich_text = true

    // start with the textarea and tinymce in sync
    textarea.value = this.getCode()
    textarea.style.height = this.state.height

    // Capture click events outside the iframe
    document.addEventListener('click', this.handleExternalClick)

    if (document.body.classList.contains('Underline-All-Links__enabled')) {
      this.iframe.contentDocument.body.classList.add('Underline-All-Links__enabled')
    }
    editor.on('wordCountUpdate', this.onWordCountUpdate)
    // add an aria-label to the application div that wraps RCE
    // and change role from "application" to "document" to ensure
    // the editor gets properly picked up by screen readers
    const tinyapp = document.querySelector('.tox-tinymce[role="application"]')
    if (tinyapp) {
      tinyapp.setAttribute('aria-label', formatMessage('Rich Content Editor'))
      tinyapp.setAttribute('role', 'document')
      tinyapp.setAttribute('tabIndex', '-1')
    }

    // Adds a focusout event listener for handling screen reader navigation focus
    const header = this._elementRef.current.querySelector('.tox-editor-header')
    if (header) {
      header.addEventListener('focusout', e => {
        const leavingHeader = !header.contains(e.relatedTarget)
        if (leavingHeader) {
          this.setFocusAbilityForHeader(false)
        }
      });
    }
    this.setFocusAbilityForHeader(false)

    // Probably should do this in tinymce.scss, but we only want it in new rce
    textarea.style.resize = 'none'
    editor.on('ExecCommand', this._forceCloseFloatingToolbar)
    editor.on('keydown', this.handleKey)
    editor.on('FullscreenStateChanged', this._toggleFullscreen)
    // This propagates click events on the editor out of the iframe to the parent
    // document. We need this so that click events get captured properly by instui
    // focus-trapping components, so they properly ignore trapping focus on click.
    editor.on('click', () => window.top.document.body.click(), true)
    editor.on('Cut Paste Change input Undo Redo', debounce(this.handleInputChange, 1000))
    this.announceContextToolbars(editor)

    if (this.isAutoSaving) {
      this.initAutoSave(editor)
    }

    // first view
    this.setEditorView(this.state.editorView)

    // readonly should have been handled via the init property passed
    // to <Editor>, but it's not.
    editor.mode.set(this.props.readOnly ? 'readonly' : 'design')

    // Not using iframe_aria_text because compatibility issues.
    // Not using iframe_attrs because library overwriting.
    if (this.iframe) {
      this.iframe.setAttribute('title', formatMessage(
        'Rich Text Area. Press ALT+0 for Rich Content Editor shortcuts.'))
    }

    this.props.onInitted?.(editor)
  }

  _toggleFullscreen = event => {
    const header = document.getElementById('header')
    if (header) {
      if (event.state) {
        this.setState({
          fullscreenState: {
            headerDisp: header.style.display,
            isTinyFullscreen: true
          }
        })
        header.style.display = 'none'
      } else {
        header.style.display = this.state.fullscreenState.headerDisp
        this.setState({
          fullscreenState: {
            isTinyFullscreen: false
          }
        })
      }
    }

    // if we're leaving fullscreen, remove event listeners on the fullscreen element
    if (!document[FS_ELEMENT] && this.state.fullscreenElem) {
      this.state.fullscreenElem.removeEventListener('fullscreenchange', this._toggleFullscreen)
      this.state.fullscreenElem.removeEventListener(
        'webkitfullscreenchange',
        this._toggleFullscreen
      )
      this.setState({
        fullscreenState: {
          fullscreenElem: null
        }
      })
    }

    // if we don't defer setState, the pretty editor's height isn't correct
    // when entering fullscreen
    window.setTimeout(() => {
      if (document[FS_ELEMENT]) {
        this.setState(state => {
          return {
            fullscreenState: {
              ...state.fullscreenState,
              fullscreenElem: document[FS_ELEMENT]
            }
          }
        })
      } else {
        this.forceUpdate()
      }
      this.focusCurrentView()
    }, 0)
  }

  _forceCloseFloatingToolbar = () => {
    if (this._elementRef.current) {
      const moreButton = this._elementRef.current.querySelector(
        '.tox-toolbar-overlord .tox-toolbar__group:last-child button:last-child'
      )
      if (moreButton?.getAttribute('aria-owns')) {
        // the floating toolbar is open
        moreButton.click() // close the floating toolbar
        const editor = this.mceInstance() // return focus to the editor
        editor?.focus()
      }
    }
  }

  announcing = 0

  announceContextToolbars(editor) {
    editor.on('NodeChange', () => {
      const node = editor.selection.getNode()
      if (isImageEmbed(node, editor)) {
        if (this.announcing !== 1) {
          this.setState({
            announcement: formatMessage('type Control F9 to access image options. {text}', {
              text: node.getAttribute('alt')
            })
          })
          this.announcing = 1
        }
      } else if (isFileLink(node, editor)) {
        if (this.announcing !== 2) {
          this.setState({
            announcement: formatMessage('type Control F9 to access link options. {text}', {
              text: node.textContent
            })
          })
          this.announcing = 2
        }
      } else if (isElementWithinTable(node, editor)) {
        if (this.announcing !== 3) {
          this.setState({
            announcement: formatMessage('type Control F9 to access table options. {text}', {
              text: node.textContent
            })
          })
          this.announcing = 3
        }
      } else {
        this.setState({
          announcement: null
        })
        this.announcing = 0
      }
    })
  }

  /* ********** autosave support *************** */
  initAutoSave = editor => {
    this.storage = window.localStorage
    if (this.storage) {
      editor.on('change Undo Redo', this.doAutoSave)
      editor.on('blur', this.doAutoSave)

      this.cleanupAutoSave()

      try {
        const autosaved = this.getAutoSaved(this.autoSaveKey)
        if (autosaved && autosaved.content) {
          // We'll compare just the text of the autosave content, since
          // Canvas is prone to swizzling images and iframes which will
          // make the editor content and autosave content never match up
          const editorContent = this.patchAutosavedContent(
            editor.getContent({no_events: true}),
            true
          )
          const autosavedContent = this.patchAutosavedContent(autosaved.content, true)

          if (autosavedContent !== editorContent) {
            this.setState({
              confirmAutoSave: true,
              autoSavedContent: this.patchAutosavedContent(autosaved.content)
            })
          } else {
            this.storage.removeItem(this.autoSaveKey)
          }
        }
      } catch (ex) {
        // log and ignore
        // eslint-disable-next-line no-console
        console.error('Failed initializing rce autosave', ex)
      }
    }
  }

  // remove any autosaved value that's too old

  cleanupAutoSave = (deleteAll = false) => {
    if (this.storage) {
      const expiry = deleteAll ? Date.now() : Date.now() - this.props.autosave.maxAge
      let i = 0
      let key
      while ((key = this.storage.key(i++))) {
        if (/^rceautosave:/.test(key)) {
          const autosaved = this.getAutoSaved(key)
          if (autosaved && autosaved.autosaveTimestamp < expiry) {
            this.storage.removeItem(key)
          }
        }
      }
    }
  }

  restoreAutoSave = ans => {
    this.setState({confirmAutoSave: false}, () => {
      const editor = this.mceInstance()
      if (ans) {
        editor.setContent(this.state.autoSavedContent, {})
      }
      this.storage.removeItem(this.autoSaveKey)
    })
    this.checkAccessibility()
  }

  // if a placeholder image shows up in autosaved content, we have to remove it
  // because the data url gets converted to a blob, which is not valid when restored.
  // besides, the placeholder is intended to be temporary while the file
  // is being uploaded
  patchAutosavedContent(content, asText) {
    const temp = document.createElement('div')
    temp.innerHTML = content
    temp.querySelectorAll('[data-placeholder-for]').forEach(placeholder => {
      placeholder.parentElement.removeChild(placeholder)
    })
    if (asText) return temp.textContent
    return temp.innerHTML
  }

  getAutoSaved(key) {
    let autosaved = null
    try {
      autosaved = this.storage && JSON.parse(this.storage.getItem(key))
    } catch (_ex) {
      this.storage.removeItem(this.autoSaveKey)
    }
    return autosaved
  }

  // only autosave if the feature flag is set, and there is only 1 RCE on the page
  // the latter condition is necessary because the popup RestoreAutoSaveModal
  // is lousey UX when there are >1
  get isAutoSaving() {
    // If the editor is invisible for some reason, don't show the autosave modal
    // This doesn't apply if the editor is off-screen or has visibility:hidden;
    // only if it isn't rendered or has display:none;
    const editorVisible = this.editor.getContainer().offsetParent

    return (
      this.props.autosave.enabled &&
      editorVisible &&
      document.querySelectorAll('.rce-wrapper').length === 1 &&
      storageAvailable()
    )
  }

  get autoSaveKey() {
    const userId = this.props.trayProps?.containingContext.userId
    return `rceautosave:${userId}${window.location.href}:${this.props.textareaId}`
  }

  doAutoSave = (e, retry = false) => {
    if (this.storage) {
      const editor = this.mceInstance()
      // if the editor is empty don't save
      if (editor.dom.isEmpty(editor.getBody())) {
        return
      }

      const content = editor.getContent({no_events: true})
      try {
        this.storage.setItem(
          this.autoSaveKey,
          JSON.stringify({
            autosaveTimestamp: Date.now(),
            content
          })
        )
      } catch (ex) {
        if (!retry) {
          // probably failed because there's not enough space
          // delete up all the other entries and try again
          this.cleanupAutoSave(true)
          this.doAutoSave(e, true)
        } else {
          console.error('Autosave failed:', ex) // eslint-disable-line no-console
        }
      }
    }
  }
  /* *********** end autosave support *************** */

  onWordCountUpdate = e => {
    this.setState(state => {
      if (e.wordCount.words !== state.wordCount) {
        return {wordCount: e.wordCount.words}
      } else return null
    })
  }

  onNodeChange = e => {
    // This is basically copied out of the tinymce silver theme code for the status bar
    const path = e.parents
      .filter(
        p =>
          p.nodeName !== 'BR' &&
          !p.getAttribute('data-mce-bogus') &&
          p.getAttribute('data-mce-type') !== 'bookmark'
      )
      .map(p => p.nodeName.toLowerCase())
      .reverse()
    this.setState({path})
  }

  onEditorChange = (content, _editor) => {
    this.props.onContentChange?.(content)
  }

  onResize = (_e, coordinates) => {
    const editor = this.mceInstance()
    if (editor) {
      const container = editor.getContainer()
      if (!container) return
      const currentContainerHeight = Number.parseInt(container.style.height, 10)
      if (isNaN(currentContainerHeight)) return // eslint-disable-line no-restricted-globals
      const modifiedHeight = currentContainerHeight + coordinates.deltaY
      const newHeight = `${modifiedHeight}px`
      container.style.height = newHeight
      this.getTextarea().style.height = newHeight
      this.setState({height: newHeight})
      // play nice and send the same event that the silver theme would send
      editor.fire('ResizeEditor')
    }
  }

  onA11yChecker = () => {
    // eslint-disable-next-line promise/catch-or-return
    this.a11yCheckerReady.then(() => {
      this.onTinyMCEInstance('openAccessibilityChecker', {skip_focus: true})
    })
  }

  checkAccessibility = () => {
    const editor = this.mceInstance()
    editor.execCommand(
      'checkAccessibility',
      false,
      {
        done: errors => {
          this.setState({a11yErrorsCount: errors.length})
        }
      },
      {skip_focus: true}
    )
  }

  openKBShortcutModal = () => {
    this.setState({
      KBShortcutModalOpen: true,
      KBShortcutFocusReturn: document.activeElement
    })
  }

  closeKBShortcutModal = () => {
    this.setState({KBShortcutModalOpen: false})
  }

  KBShortcutModalExited = () => {
    if (this.state.KBShortcutFocusReturn === this.iframe) {
      // if the iframe has focus, we need to forward it on to tinymce
      this.editor.focus(false)
    } else if (this._showOnFocusButton && document.activeElement === document.body) {
      // when the modal is opened from the showOnFocus button, focus doesn't
      // get automatically returned to the button like it should.
      this._showOnFocusButton.focus()
    } else {
      this._showOnFocusButton?.focus()
    }
  }

  setFocusAbilityForHeader = (focusable) => {
    // Sets aria-hidden to prevent screen readers focus in RCE menus and toolbar
    const header = this._elementRef.current.querySelector('.tox-editor-header')
    if (header) {
      header.setAttribute('aria-hidden', focusable ? 'false' : 'true')
    }
  }

  componentWillUnmount() {
    if (this.state.shouldShowEditor) {
      window.clearTimeout(this.blurTimer)
      if (!this._destroyCalled) {
        this.destroy()
      }
      this._elementRef.current.removeEventListener('keydown', this.handleKey, true)
      this.mutationObserver?.disconnect()
      this.intersectionObserver?.disconnect()
    }
  }

  wrapOptions(options = {}) {
    const rcsExists = !!(this.props.trayProps?.host && this.props.trayProps?.jwt)

    const setupCallback = options.setup

    const canvasPlugins = rcsExists
      ? [
          'instructure_links',
          'instructure_image',
          'instructure_documents',
          'instructure_equation',
          'instructure_external_tools'
        ]
      : ['instructure_links']
    if (rcsExists && !this.props.instRecordDisabled) {
      canvasPlugins.splice(2, 0, 'instructure_record')
    }

    if (
      rcsExists &&
      this.props.use_rce_buttons_and_icons &&
      this.props.trayProps?.contextType === 'course'
    ) {
      canvasPlugins.push('instructure_buttons')
    }

    const possibleNewMenubarItems = this.props.editorOptions.menu
      ? Object.keys(this.props.editorOptions.menu).join(' ')
      : undefined

    const wrappedOpts = {
      ...options,

      readonly: this.props.readOnly,

      theme: 'silver', // some older code specified 'modern', which doesn't exist any more

      height: options.height || DEFAULT_RCE_HEIGHT,

      language: editorLanguage(this.language),

      block_formats:
        options.block_formats ||
        [
          `${formatMessage('Heading 2')}=h2`,
          `${formatMessage('Heading 3')}=h3`,
          `${formatMessage('Heading 4')}=h4`,
          `${formatMessage('Preformatted')}=pre`,
          `${formatMessage('Paragraph')}=p`
        ].join('; '),

      setup: editor => {
        addKebabIcon(editor)
        editorWrappers.set(editor, this)
        const trayPropsWithColor = {
          brandColor: this.theme.canvasBrandColor,
          ...this.props.trayProps
        }
        bridge.trayProps?.set(editor, trayPropsWithColor)
        bridge.languages = this.props.languages
        if (typeof setupCallback === 'function') {
          setupCallback(editor)
        }
      },

      // Consumers can, and should!, still pass a content_css prop so that the content
      // in the editor matches the styles of the app it will be displayed in when saved.
      // This is just so we inject the helper class names that tinyMCE uses for
      // things like table resizing and stuff.
      content_css: options.content_css || [],
      content_style: contentCSS,

      menubar: mergeMenuItems('edit view insert format tools table', possibleNewMenubarItems),
      // default menu options listed at https://www.tiny.cloud/docs/configure/editor-appearance/#menu
      // tinymce's default edit and table menus are fine
      // we include all the canvas specific items in the menu and toolbar
      // and rely on tinymce only showing them if the plugin is provided.
      menu: mergeMenu(
        {
          format: {
            title: formatMessage('Format'),
            items:
              'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align directionality | forecolor backcolor | removeformat'
          },
          insert: {
            title: formatMessage('Insert'),
            items:
              'instructure_links instructure_image instructure_media instructure_document instructure_buttons | instructure_equation inserttable instructure_media_embed | hr'
          },
          tools: {title: formatMessage('Tools'), items: 'wordcount lti_tools_menuitem'},
          view: {title: formatMessage('View'), items: 'fullscreen instructure_html_view'}
        },
        options.menu
      ),

      toolbar: mergeToolbar(
        [
          {
            name: formatMessage('Styles'),
            items: ['fontsizeselect', 'formatselect']
          },
          {
            name: formatMessage('Formatting'),
            items: [
              'bold',
              'italic',
              'underline',
              'forecolor',
              'backcolor',
              'inst_subscript',
              'inst_superscript'
            ]
          },
          {
            name: formatMessage('Content'),
            items: [
              'instructure_links',
              'instructure_image',
              'instructure_record',
              'instructure_documents',
              'instructure_buttons'
            ]
          },
          {
            name: formatMessage('External Tools'),
            items: [...this.ltiToolFavorites, 'lti_tool_dropdown', 'lti_mru_button']
          },
          {
            name: formatMessage('Alignment and Lists'),
            items: ['align', 'bullist', 'inst_indent', 'inst_outdent']
          },
          {
            name: formatMessage('Miscellaneous'),
            items: ['removeformat', 'table', 'instructure_equation', 'instructure_media_embed']
          }
        ],
        options.toolbar
      ),

      contextmenu: '', // show the browser's native context menu

      toolbar_mode: 'floating',
      toolbar_sticky: true,

      plugins: mergePlugins(
        [
          'autolink',
          'media',
          'paste',
          'table',
          'link',
          'directionality',
          'lists',
          'textpattern',
          'hr',
          'fullscreen',
          'instructure-ui-icons',
          'instructure_condensed_buttons',
          'instructure_links',
          'instructure_html_view',
          'instructure_media_embed',
          'instructure_external_tools',
          'a11y_checker',
          'wordcount',
          ...canvasPlugins
        ],
        sanitizePlugins(options.plugins)
      ),
      textpattern_patterns: [
        {start: '* ', cmd: 'InsertUnorderedList'},
        {start: '- ', cmd: 'InsertUnorderedList'}
      ]
    }

    if (this.props.trayProps) {
      wrappedOpts.canvas_rce_user_context = {
        type: this.props.trayProps.contextType,
        id: this.props.trayProps.contextId
      }

      wrappedOpts.canvas_rce_containing_context = {
        type: this.props.trayProps.containingContext.contextType,
        id: this.props.trayProps.containingContext.contextId
      }
    }
    return wrappedOpts
  }

  handleTextareaChange = () => {
    if (this.isHidden()) {
      this.setCode(this.textareaValue())
      this.doAutoSave()
    }
  }

  unhandleTextareaChange() {
    if (this._textareaEl) {
      this._textareaEl.removeEventListener('input', this.handleTextareaChange)
    }
  }

  registerTextareaChange() {
    const el = this.getTextarea()
    if (this._textareaEl !== el) {
      this.unhandleTextareaChange()
      if (el) {
        el.addEventListener('input', this.handleTextareaChange)
        if (this.props.textareaClassName) {
          // split the string on whitespace because classList doesn't let you add multiple
          // space seperated classes at a time but does let you add an array of them
          el.classList.add(...this.props.textareaClassName.split(/\s+/))
        }
        this._textareaEl = el
      }
    }
  }

  componentDidMount() {
    if (this.state.shouldShowEditor) {
      this.editorReallyDidMount()
    } else {
      this.intersectionObserver = new IntersectionObserver(
        entries => {
          const entry = entries[0]
          if (entry.isIntersecting || entry.intersectionRatio > 0) {
            this.setState({shouldShowEditor: true})
          }
        },
        // initialize the RCE when it gets close to entering the viewport
        {root: null, rootMargin: '200px 0px', threshold: 0.0}
      )
      this.intersectionObserver.observe(this._editorPlaceholderRef.current)
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.shouldShowEditor) {
      if (!prevState.shouldShowEditor) {
        this.editorReallyDidMount()
        this.intersectionObserver?.disconnect()
      } else {
        this.registerTextareaChange()
        if (prevState.editorView !== this.state.editorView) {
          this.setEditorView(this.state.editorView)
          this.focusCurrentView()
        }
        if (prevProps.readOnly !== this.props.readOnly) {
          this.mceInstance().mode.set(this.props.readOnly ? 'readonly' : 'design')
        }
      }
    }
  }

  editorReallyDidMount() {
    const myTiny = this.mceInstance()
    this.pendingEventHandlers.forEach(e => {
      myTiny.on(e.name, e.handler)
    })
    this.registerTextareaChange()
    this._elementRef.current.addEventListener('keydown', this.handleKey, true)
    // give the textarea its initial size
    this.onResize(null, {deltaY: 0})
    // Preload the LTI Tools modal
    // This helps with loading the favorited external tools
    if (this.ltiToolFavorites.length > 0) {
      import('./plugins/instructure_external_tools/components/LtiToolsModal')
    }

    // .tox-tinymce-aux is where tinymce puts the floating toolbar when
    // the user clicks the More... button
    // Tinymce doesn't fire onFocus when the user clicks More... from somewhere
    // outside, so we'll handle that here by watching for the floating toolbar
    // to come and go.
    const portals = document.querySelectorAll('.tox-tinymce-aux')
    // my portal will be the last one in the doc because tinyumce appends them
    const tinymce_floating_toolbar_portal = portals[portals.length - 1]
    if (tinymce_floating_toolbar_portal) {
      this.mutationObserver = new MutationObserver((mutationList, _observer) => {
        mutationList.forEach(mutation => {
          if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
            this.handleFocusEditor(new Event('focus', {target: mutation.target}))
          }
        })
      })
      this.mutationObserver.observe(tinymce_floating_toolbar_portal, {childList: true})
    }
    bridge.renderEditor(this)
  }

  setEditorView(view) {
    switch (view) {
      case RAW_HTML_EDITOR_VIEW:
        this.getTextarea().removeAttribute('aria-hidden')
        this.getTextarea().labels?.[0]?.removeAttribute('aria-hidden')
        this.mceInstance().hide()
        break
      case PRETTY_HTML_EDITOR_VIEW:
        this.getTextarea().setAttribute('aria-hidden', true)
        this.getTextarea().labels?.[0]?.setAttribute('aria-hidden', true)
        this.mceInstance().hide()
        this._elementRef.current.querySelector('.CodeMirror')?.CodeMirror.setCursor(0, 0)
        break
      case WYSIWYG_VIEW:
        this.setCode(this.textareaValue())
        this.getTextarea().setAttribute('aria-hidden', true)
        this.getTextarea().labels?.[0]?.setAttribute('aria-hidden', true)
        this.mceInstance().show()
    }
  }

  addAlert = alert => {
    alert.id = alertIdValue++
    this.setState(state => {
      let messages = state.messages.concat(alert)
      messages = _.uniqBy(messages, 'text') // Don't show the same message twice
      return {messages}
    })
  }

  removeAlert = messageId => {
    this.setState(state => {
      const messages = state.messages.filter(message => message.id !== messageId)
      return {messages}
    })
  }

  /**
   * Used for reseting the value during tests
   */
  resetAlertId = () => {
    if (this.state.messages.length > 0) {
      throw new Error('There are messages currently, you cannot reset when they are non-zero')
    }
    alertIdValue = 0
  }

  renderHtmlEditor() {
    // the div keeps the editor from collapsing while the code editor is downloaded
    return (
      <Suspense
        fallback={
          <div
            style={{
              height: this.state.height,
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center'
            }}
          >
            <Spinner renderTitle={renderLoading} size="medium" />
          </div>
        }
      >
        <View as="div" borderRadius="medium" borderWidth="small">
          <RceHtmlEditor
            ref={this._prettyHtmlEditorRef}
            height={document[FS_ELEMENT] ? `${window.screen.height}px` : this.state.height}
            code={this.getCode()}
            onChange={value => {
              this.getTextarea().value = value
              this.handleTextareaChange()
            }}
            onFocus={this.handleFocusHtmlEditor}
          />
        </View>
      </Suspense>
    )
  }

  render() {
    const {trayProps, ...mceProps} = this.props

    if (!this.state.shouldShowEditor) {
      return (
        <div
          ref={this._editorPlaceholderRef}
          style={{
            width: `${this.props.editorOptions.width}px`,
            height: `${this.props.editorOptions.height}px`,
            border: '1px solid grey'
          }}
        />
      )
    }
    return (
      <div
        key={this.id}
        className={`${styles.root} rce-wrapper`}
        ref={this._elementRef}
        onFocus={this.handleFocusRCE}
        onBlur={this.handleBlurRCE}
      >
        {this.state.shouldShowOnFocusButton && (
          <ShowOnFocusButton
            onClick={this.openKBShortcutModal}
            margin="xx-small"
            screenReaderLabel={formatMessage('View keyboard shortcuts')}
            ref={el => (this._showOnFocusButton = el)}
          >
            <IconKeyboardShortcutsLine />
          </ShowOnFocusButton>
        )}
        <AlertMessageArea
          messages={this.state.messages}
          liveRegion={this.props.liveRegion}
          afterDismiss={this.removeAlert}
        />
        {this.state.editorView === PRETTY_HTML_EDITOR_VIEW && this.renderHtmlEditor()}
        <div
          style={{display: this.state.editorView === PRETTY_HTML_EDITOR_VIEW ? 'none' : 'block'}}
        >
          <Editor
            id={mceProps.textareaId}
            textareaName={mceProps.name}
            init={this.tinymceInitOptions}
            initialValue={mceProps.defaultContent}
            onInit={this.onInit}
            onClick={this.handleFocusEditor}
            onKeypress={this.handleFocusEditor}
            onActivate={this.handleFocusEditor}
            onRemove={this.onRemove}
            onFocus={this.handleFocusEditor}
            onBlur={this.handleBlurEditor}
            onNodeChange={this.onNodeChange}
            onEditorChange={this.onEditorChange}
          />
        </div>
        <StatusBar
          readOnly={this.props.readOnly}
          onChangeView={newView => this.toggleView(newView)}
          path={this.state.path}
          wordCount={this.state.wordCount}
          editorView={this.state.editorView}
          preferredHtmlEditor={getHtmlEditorCookie()}
          onResize={this.onResize}
          onKBShortcutModalOpen={this.openKBShortcutModal}
          onA11yChecker={this.onA11yChecker}
          onFullscreen={this.handleClickFullscreen}
          a11yBadgeColor={this.theme.canvasBadgeBackgroundColor}
          a11yErrorsCount={this.state.a11yErrorsCount}
        />
        {this.props.trayProps && this.props.trayProps.containingContext && (
          <CanvasContentTray
            key={this.id}
            bridge={bridge}
            editor={this}
            onTrayClosing={this.handleContentTrayClosing}
            use_rce_buttons_and_icons={this.props.use_rce_buttons_and_icons}
            {...trayProps}
          />
        )}
        <KeyboardShortcutModal
          onExited={this.KBShortcutModalExited}
          onDismiss={this.closeKBShortcutModal}
          open={this.state.KBShortcutModalOpen}
        />
        {this.state.confirmAutoSave ? (
          <Suspense fallback={<Spinner renderTitle={renderLoading} size="small" />}>
            <RestoreAutoSaveModal
              savedContent={this.state.autoSavedContent}
              open={this.state.confirmAutoSave}
              onNo={() => this.restoreAutoSave(false)}
              onYes={() => this.restoreAutoSave(true)}
            />
          </Suspense>
        ) : null}
        <Alert screenReaderOnly liveRegion={this.props.liveRegion}>
          {this.state.announcement}
        </Alert>
      </div>
    )
  }
}

// standard: string of tinymce menu commands
// e.g. 'instructure_links | inserttable instructure_media_embed | hr'
// custom: a string of tinymce menu commands
// returns: standard + custom with any duplicate commands removed from custom
function mergeMenuItems(standard, custom) {
  let c = custom?.trim?.()
  if (!c) return standard

  const s = new Set(standard.split(/[\s|]+/))
  // remove any duplicates
  c = c.split(/\s+/).filter(m => !s.has(m))
  c = c
    .join(' ')
    .replace(/^\s*\|\s*/, '')
    .replace(/\s*\|\s*$/, '')
  return `${standard} | ${c}`
}

// standard: the incoming tinymce menu object
// custom: tinymce menu object to merge into standard
// returns: the merged result by mutating incoming standard arg.
// It will add commands to existing menus, or add a new menu
// if the custom one does not exist
function mergeMenu(standard, custom) {
  if (!custom) return standard

  Object.keys(custom).forEach(k => {
    const curr_m = standard[k]
    if (curr_m) {
      curr_m.items = mergeMenuItems(curr_m.items, custom[k].items)
    } else {
      standard[k] = {...custom[k]}
    }
  })
  return standard
}

// standard: incoming tinymce toolbar array
// custom: tinymce toolbar array to merge into standard
// returns: the merged result by mutating the incoming standard arg.
// It will add commands to existing toolbars, or add a new toolbar
// if the custom one does not exist
function mergeToolbar(standard, custom) {
  if (!custom) return standard
  // merge given toolbar data into the default toolbar
  custom.forEach(tb => {
    const curr_tb = standard.find(t => tb.name && formatMessage(tb.name) === t.name)
    if (curr_tb) {
      curr_tb.items.splice(curr_tb.items.length, 0, ...tb.items)
    } else {
      standard.push(tb)
    }
  })
  return standard
}

// standard: incoming array of plugin names
// custom: array of plugin names to merge
// returns: the merged result, duplicates removed
function mergePlugins(standard, custom) {
  if (!custom) return standard

  const union = new Set(standard)
  for (const p of custom) {
    union.add(p)
  }
  return [...union]
}

export default RCEWrapper
export {
  toolbarPropType,
  menuPropType,
  ltiToolsPropType,
  mergeMenuItems,
  mergeMenu,
  mergeToolbar,
  mergePlugins
}
