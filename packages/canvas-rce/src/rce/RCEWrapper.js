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
import uniqBy from 'lodash/uniqBy'

import themeable from '@instructure/ui-themeable'
import {IconKeyboardShortcutsLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-elements'

import formatMessage from '../format-message'
import * as contentInsertion from './contentInsertion'
import indicatorRegion from './indicatorRegion'
import indicate from '../common/indicate'
import Bridge from '../bridge'
import CanvasContentTray, {trayProps} from './plugins/shared/CanvasContentTray'
import StatusBar from './StatusBar'
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

const ASYNC_FOCUS_TIMEOUT = 250

// we  `require` instead of `import` these 2 css files because the ui-themeable babel require hook only works with `require`
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

function showMenubar(el, show) {
  const $menubar = el.querySelector('.tox-menubar')
  $menubar && ($menubar.style.display = show ? '' : 'none')
  if (show) {
    focusFirstMenuButton(el)
  }
}

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
function storageAvailable() {
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

function renderLoading() {
  return formatMessage('Loading')
}

let alertIdValue = 0

@themeable(theme, styles)
class RCEWrapper extends React.Component {
  static getByEditor(editor) {
    return editorWrappers.get(editor)
  }

  static propTypes = {
    autosave: PropTypes.shape({
      enabled: PropTypes.bool,
      rce_auto_save_max_age_ms: PropTypes.number
    }),
    confirmFunc: PropTypes.func,
    defaultContent: PropTypes.string,
    editorOptions: PropTypes.object,
    handleUnmount: PropTypes.func,
    language: PropTypes.string,
    onFocus: PropTypes.func,
    onBlur: PropTypes.func,
    onRemove: PropTypes.func,
    textareaClassName: PropTypes.string,
    textareaId: PropTypes.string,
    languages: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        label: PropTypes.string.isRequired
      })
    ),
    tinymce: PropTypes.object,
    trayProps
  }

  static defaultProps = {
    trayProps: null,
    languages: [{id: 'en', label: 'English'}],
    autosave: {enabled: false}
  }

  static skinCssInjected = false

  constructor(props) {
    super(props)

    this.editor = null // my tinymce editor instance

    // interface consistent with editorBox
    this.get_code = this.getCode
    this.set_code = this.setCode
    this.insert_code = this.insertCode

    // test override points
    this.indicator = false

    this._elementRef = null
    this._showOnFocusButton = null

    injectTinySkin()

    this.state = {
      path: [],
      wordCount: 0,
      isHtmlView: false,
      KBShortcutModalOpen: false,
      focused: false,
      messages: [],
      announcement: null,
      confirmAutoSave: false,
      autoSavedContent: ''
    }

    alertHandler.alertFunc = this.addAlert
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
    this.mceInstance().setContent(newContent)
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
    const element = contentInsertion.insertImage(editor, image)
    if (element && element.complete) {
      this.contentInserted(element)
    } else if (element) {
      element.onload = () => this.contentInserted(element)
      element.onerror = () => this.checkImageLoadError(element)
    }
  }

  insertImagePlaceholder(fileMetaProps) {
    let width, height
    if (isImage(fileMetaProps.contentType)) {
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
    } else if (isAudio(fileMetaProps.contentType || fileMetaProps.type)) {
      width = AUDIO_PLAYER_SIZE.width
      height = AUDIO_PLAYER_SIZE.height
    } else {
      width = `${fileMetaProps.name.length}rem`
      height = '1rem'
    }
    const markup = `
    <img
      alt="${formatMessage('Loading...')}"
      src="data:image/gif;base64,R0lGODlhAQABAIAAAMLCwgAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw=="
      data-placeholder-for="${fileMetaProps.name}"
      style="width: ${width}; height: ${height}; border: solid 1px #8B969E;"
    />`

    this.insertCode(markup)
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

  removePlaceholders(name) {
    const placeholder = this.mceInstance().dom.doc.querySelector(`[data-placeholder-for="${name}"]`)
    if (placeholder) {
      placeholder.remove()
    }
  }

  insertLink(link, isNew) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertLink(editor, link, isNew)
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
    this.onTinyMCEInstance('mceRemoveEditor')
    this.unhandleTextareaChange()
    this.props.handleUnmount && this.props.handleUnmount()
  }

  onRemove = () => {
    Bridge.detachEditor(this)
    this.props.onRemove && this.props.onRemove(this)
  }

  getTextarea() {
    return document.getElementById(this.props.textareaId)
  }

  textareaValue() {
    return this.getTextarea().value
  }

  toggle = () => {
    if (this.isHidden()) {
      this.setState({isHtmlView: false})
    } else {
      this.setState({isHtmlView: true})
    }
  }

  focus() {
    this.onTinyMCEInstance('mceFocus')
  }

  is_dirty() {
    const content = this.isHidden() ? this.textareaValue() : this.mceInstance().getContent()
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

  isHidden() {
    return this.mceInstance().isHidden()
  }

  get iframe() {
    return document.getElementById(`${this.props.textareaId}_ifr`)
  }

  // these focus and blur event handlers work together so that RCEWrapper
  // can report focus and blur events from the RCE at-large
  get focused() {
    return this.state.focused
  }

  handleFocus(_event) {
    if (!this.state.focused) {
      this.setState({focused: true})
      Bridge.focusEditor(this)
      this._forceCloseFloatingToolbar()
      this.props.onFocus && this.props.onFocus(this)
    }
  }

  contentTrayClosing = false

  handleContentTrayClosing = isClosing => {
    this.contentTrayClosing = isClosing
  }

  blurTimer = 0

  handleBlur(event) {
    if (this.blurTimer) return

    if (this.state.focused) {
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

        if (this._elementRef && this._elementRef.contains(document.activeElement)) {
          // focus is still somewhere w/in me
          return
        }

        const activeClass = document.activeElement && document.activeElement.getAttribute('class')
        if (activeClass && activeClass.includes('tox-')) {
          // if a toolbar button has focus, then the user clicks on the "more" button
          // focus jumps to the body, then eventually to the popped up toolbar. This
          // catches that case, but could also fail to blur an rce if the user clicked from
          // one rce on the page to another.  I think this is the lesser of the 2 evils
          return
        }

        if (event?.relatedTarget?.getAttribute('class')?.includes('tox-')) {
          // a tinymce popup has focus
          return
        }

        const popup = document.querySelector('[data-mce-component]')
        if (popup && popup.contains(document.activeElement)) {
          // one of our popups has focus
          return
        }
        this.setState({focused: false})
        this.props.onBlur && this.props.onBlur(event)
      }, ASYNC_FOCUS_TIMEOUT)
    }
  }

  handleFocusRCE = event => {
    if (this._elementRef && !this._elementRef.contains(event.relatedTarget)) {
      this.handleFocus(event)
    }
  }

  handleBlurRCE = event => {
    if (event.relatedTarget === null) {
      // focus might be moving to tinymce
      this.handleBlur(event)
    }

    if (!this._elementRef.contains(event.relatedTarget)) {
      this.handleBlur(event)
    }
  }

  handleFocusEditor = (event, _editor) => {
    // use .active to put a focus ring around the content area
    // when the editor has focus. This isn't perfect, but it's
    // what we've got for now.
    const ifr = this.iframe
    ifr && ifr.parentElement.classList.add('active')

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

  initKeyboardShortcuts(el, editor) {
    // hide the menubar
    showMenubar(el, false)

    // when typed w/in the editor's edit area
    editor.addShortcut('Alt+F9', '', () => {
      showMenubar(el, true)
    })
    // when typed somewhere else w/in RCEWrapper
    el.addEventListener('keydown', event => {
      if (event.altKey && event.code === 'F9') {
        event.preventDefault()
        event.stopPropagation()
        showMenubar(el, true)
      }
    })

    // toolbar help
    el.addEventListener('keydown', event => {
      if (event.altKey && event.code === 'F10') {
        event.preventDefault()
        event.stopPropagation()
        focusToolbar(el)
      }
    })

    editor.on('keydown', this.handleShortcutKeyShortcut)
  }

  onInit = (_event, editor) => {
    editor.rceWrapper = this
    this.editor = editor

    this.initKeyboardShortcuts(this._elementRef, editor)
    if (document.body.classList.contains('Underline-All-Links__enabled')) {
      this.iframe.contentDocument.body.classList.add('Underline-All-Links__enabled')
    }
    editor.on('wordCountUpdate', this.onWordCountUpdate)
    // and an aria-label to the application div that wraps RCE
    const tinyapp = document.querySelector('.tox-tinymce[role="application"]')
    if (tinyapp) {
      tinyapp.setAttribute('aria-label', formatMessage('Rich Content Editor'))
    }
    // Probably should do this in tinymce.scss, but we only want it in new rce
    this.getTextarea().style.resize = 'none'
    editor.on('Change', this.doAutoResize)

    editor.on('ExecCommand', this._forceCloseFloatingToolbar)

    this.announceContextToolbars(editor)

    if (this.isAutoSaving) {
      this.initAutoSave(editor)
    }
  }

  _forceCloseFloatingToolbar = () => {
    if (this._elementRef) {
      const moreButton = this._elementRef.querySelector(
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

  doAutoResize = e => {
    const ifr = this.iframe
    if (ifr) {
      const contentElm = ifr.contentDocument.documentElement
      if (contentElm.scrollHeight > contentElm.clientHeight) {
        this.onResize(e, {deltaY: contentElm.scrollHeight - contentElm.clientHeight})
      }
    }
  }

  /* ********** autosave support *************** */
  initAutoSave = editor => {
    this.storage = window.localStorage
    if (this.storage) {
      editor.on('change', this.doAutoSave)
      editor.on('blur', this.doAutoSave)
      window.addEventListener('unload', e => {
        this.doAutoSave(e)
      })

      this.cleanupAutoSave()

      try {
        const autosaved = this.getAutoSaved(this.autoSaveKey)
        if (autosaved && autosaved.content) {
          const editorContent = editor.getContent({no_events: true})
          const autosavedContent = this.patchAutosavedContent(autosaved.content)
          if (autosaved.content !== editorContent) {
            this.setState({
              confirmAutoSave: true,
              autoSavedContent: autosavedContent
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
    const expiry = deleteAll
      ? Date.now()
      : Date.now() - this.props.autosave.rce_auto_save_max_age_ms
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

  restoreAutoSave = ans => {
    this.setState({confirmAutoSave: false}, () => {
      const editor = this.mceInstance()
      if (ans) {
        editor.setContent(this.state.autoSavedContent, {})
      }
      this.storage.removeItem(this.autoSaveKey)
    })
  }

  // if a placeholder image shows up in autosaved content, we have to remove it
  // because the data url gets converted to a blob, which is not valid when restored.
  // besides, the placeholder is intended to be temporary while the file
  // is being uploaded
  patchAutosavedContent(content) {
    const temp = document.createElement('div')
    temp.innerHTML = content
    temp.querySelectorAll('img[data-placeholder-for]').forEach(placeholder => {
      placeholder.parentElement.removeChild(placeholder)
    })
    return temp.innerHTML
  }

  getAutoSaved(key) {
    let autosaved = null
    try {
      autosaved = JSON.parse(this.storage.getItem(key))
    } catch (_ex) {
      this.storage.removeItem(this.autoSaveKey)
    }
    return autosaved
  }

  // only autosave if the feature flag is set, and there is only 1 RCE on the page
  // the latter condition is necessary because the popup RestoreAutoSaveModal
  // is lousey UX when there are >1
  get isAutoSaving() {
    return (
      this.props.autosave.enabled &&
      document.querySelectorAll('.rce-wrapper').length === 1 &&
      storageAvailable()
    )
  }

  get autoSaveKey() {
    return `rceautosave:${window.location.href}:${this._textareaEl.id}`
  }

  doAutoSave = (e, retry = false) => {
    const editor = this.mceInstance()
    // if the editor is empty don't save
    if (editor.dom.isEmpty(editor.getBody())) {
      return
    }
    // if no changes have been made,
    // delete and don't save
    if (!editor.isDirty()) {
      this.storage.removeItem(this.autoSaveKey)
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
      // play nice and send the same event that the silver theme would send
      editor.fire('ResizeEditor')
    }
  }

  onA11yChecker = () => {
    this.onTinyMCEInstance('openAccessibilityChecker', {skip_focus: true})
  }

  handleShortcutKeyShortcut = event => {
    if (event.altKey && (event.keyCode === 48 || event.keyCode === 119)) {
      event.preventDefault()
      event.stopPropagation()
      this.openKBShortcutModal()
    } else if (event.keyCode === 27) {
      // ESC
      this._forceCloseFloatingToolbar()
    }
  }

  openKBShortcutModal = () => {
    this.setState({KBShortcutModalOpen: true})
  }

  closeKBShortcutModal = () => {
    this.setState({KBShortcutModalOpen: false})
  }

  KBShortcutModalClosed = () => {
    // when the modal is opened from the showOnFocus button, focus doesn't
    // get automatically returned to the button like it should.
    if (this._showOnFocusButton && document.activeElement === document.body) {
      this._showOnFocusButton.focus()
    }
  }

  componentWillUnmount() {
    window.clearTimeout(this.blurTimer)
    if (!this._destroyCalled) {
      this.destroy()
    }
    this._elementRef.removeEventListener('keyup', this.handleShortcutKeyShortcut, true)
  }

  wrapOptions(options = {}) {
    const setupCallback = options.setup

    return {
      ...options,

      block_formats: [
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
        Bridge.trayProps.set(editor, trayPropsWithColor)
        Bridge.languages = this.props.languages
        if (typeof setupCallback === 'function') {
          setupCallback(editor)
        }
      },

      // Consumers can, and should!, still pass a content_css prop so that the content
      // in the editor matches the styles of the app it will be displayed in when saved.
      // This is just so we inject the helper class names that tinyMCE uses for
      // things like table resizing and stuff.
      content_style: contentCSS,

      toolbar: [
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
          name: formatMessage('Alignment and Indentation'),
          items: ['align', 'bullist', 'inst_indent', 'inst_outdent', 'directionality']
        },
        {
          name: formatMessage('Canvas Plugins'),
          items: [
            'instructure_links',
            'instructure_image',
            'instructure_record',
            'instructure_documents'
          ]
        },
        {
          name: formatMessage('Miscellaneous and Apps'),
          items: ['removeformat', 'table', 'instructure_equation', 'lti_tool_dropdown']
        }
      ],
      contextmenu: '', // show the browser's native context menu

      toolbar_drawer: 'floating',
      toolbar_sticky: true,

      // tiny's external link create/edit dialog config
      target_list: false, // don't show the target list when creating/editing links
      link_title: false, // don't show the title input when creating/editing links
      default_link_target: '_blank',

      canvas_rce_user_context: {
        type: this.props.trayProps.contextType,
        id: this.props.trayProps.contextId
      }
    }
  }

  handleTextareaChange = () => {
    if (this.isHidden()) {
      this.setCode(this.textareaValue())
    }
  }

  unhandleTextareaChange() {
    if (this._textareaEl) {
      this._textareaEl.removeEventListener('change', this.handleTextareaChange)
    }
  }

  registerTextareaChange() {
    const el = this.getTextarea()
    if (this._textareaEl !== el) {
      this.unhandleTextareaChange()
      if (el) {
        el.addEventListener('change', this.handleTextareaChange)
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
    this.registerTextareaChange()
    this._elementRef.addEventListener('keyup', this.handleShortcutKeyShortcut, true)
    // give the textarea its initial size
    this.onResize(null, {deltaY: 0})
  }

  componentDidUpdate(_prevProps, prevState) {
    const {...mceProps} = this.props
    this.registerTextareaChange()
    if (prevState.isHtmlView !== this.state.isHtmlView) {
      if (this.state.isHtmlView) {
        this.getTextarea().removeAttribute('aria-hidden')
        this.mceInstance().hide()
        document.getElementById(mceProps.textareaId).focus()
      } else {
        this.setCode(this.textareaValue())
        this.getTextarea().setAttribute('aria-hidden', true)
        this.mceInstance().show()
        this.mceInstance().focus()
        this.doAutoResize()
      }
    }
  }

  addAlert = alert => {
    alert.id = alertIdValue++
    this.setState(state => {
      let messages = state.messages.concat(alert)
      messages = uniqBy(messages, 'text') // Don't show the same message twice
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

  render() {
    const {trayProps, ...mceProps} = this.props

    return (
      <div
        className={`${styles.root} rce-wrapper`}
        ref={el => (this._elementRef = el)}
        onFocus={this.handleFocusRCE}
        onBlur={this.handleBlurRCE}
      >
        <ShowOnFocusButton
          buttonProps={{
            variant: 'link',
            onClick: this.openKBShortcutModal,
            icon: IconKeyboardShortcutsLine,
            margin: 'xx-small'
          }}
          ref={el => (this._showOnFocusButton = el)}
        >
          <ScreenReaderContent>{formatMessage('View keyboard shortcuts')}</ScreenReaderContent>
        </ShowOnFocusButton>
        <AlertMessageArea
          messages={this.state.messages}
          liveRegion={trayProps.liveRegion}
          afterDismiss={this.removeAlert}
        />
        <Editor
          id={mceProps.textareaId}
          textareaName={mceProps.name}
          init={this.wrapOptions(mceProps.editorOptions)}
          initialValue={mceProps.defaultContent}
          onInit={this.onInit}
          onClick={this.handleFocusEditor}
          onKeypress={this.handleFocusEditor}
          onActivate={this.handleFocusEditor}
          onRemove={this.onRemove}
          onFocus={this.handleFocusEditor}
          onBlur={this.handleBlurEditor}
          onNodeChange={this.onNodeChange}
        />
        <StatusBar
          onToggleHtml={this.toggle}
          path={this.state.path}
          wordCount={this.state.wordCount}
          isHtmlView={this.state.isHtmlView}
          onResize={this.onResize}
          onKBShortcutModalOpen={this.openKBShortcutModal}
          onA11yChecker={this.onA11yChecker}
        />
        <CanvasContentTray
          bridge={Bridge}
          onTrayClosing={this.handleContentTrayClosing}
          {...trayProps}
        />
        <KeyboardShortcutModal
          onClose={this.KBShortcutModalClosed}
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
        <Alert
          screenReaderOnly
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
        >
          {this.state.announcement}
        </Alert>
      </div>
    )
  }
}

export default RCEWrapper
