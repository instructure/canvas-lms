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

import React, {ReactNode, Suspense} from 'react'
import {Editor} from '@tinymce/tinymce-react'

import tinymce from 'tinymce'
import type {Editor as TinyMCEEditor} from 'tinymce'
import _ from 'lodash'
import {StoreProvider} from './plugins/shared/StoreContext'

import {IconKeyboardShortcutsLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {debounce} from '@instructure/debounce'
import {uid} from '@instructure/uid'
import {FocusRegionManager} from '@instructure/ui-a11y-utils'
import getCookie from '../common/getCookie'

import formatMessage from '../format-message'
import * as contentInsertion from './contentInsertion'
import indicatorRegion from './indicatorRegion'
import {editorLanguage} from './editorLanguage'
import normalizeLocale from './normalizeLocale'
import {sanitizePlugins} from './sanitizePlugins'
import RCEGlobals from './RCEGlobals'
import defaultTinymceConfig from '../defaultTinymceConfig'
import {
  FS_CHANGEEVENT,
  FS_ELEMENT,
  FS_ENABLED,
  FS_EXIT,
  FS_REQUEST,
  instuiPopupMountNodeFn,
} from '../util/fullscreenHelpers'

import indicate from '../common/indicate'
import bridge from '../bridge'
import CanvasContentTray from './plugins/shared/CanvasContentTray'
import StatusBar, {PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW, WYSIWYG_VIEW} from './StatusBar'
import {VIEW_CHANGE} from './customEvents'
import ShowOnFocusButton from './ShowOnFocusButton'
import KeyboardShortcutModal from './KeyboardShortcutModal'
import AlertMessageArea from './AlertMessageArea'
import alertHandler from './alertHandler'
import {isFileLink, isImageEmbed} from './plugins/shared/ContentSelection'
import {countShouldIgnore} from './plugins/instructure_wordcount/utils/countContent'
import launchWordcountModal from './plugins/instructure_wordcount/clickCallback'
import {determineOSDependentKey} from './userOS'

import skinCSS from './tinymce.oxide.skin.min.css'
import contentCSS from './tinymce.oxide.content.min.css'
import {rceWrapperPropTypes} from './RCEWrapperProps'
import {
  insertPlaceholder,
  PlaceHoldableThingInfo,
  placeholderInfoFor,
  removePlaceholder,
} from '../util/loadingPlaceholder'
import {transformRceContentForEditing} from './transformContent'
// @ts-expect-error
import {IconMoreSolid} from '@instructure/ui-icons/es/svg'
import EncryptedStorage from '../util/encrypted-storage'
import buildStyle from './style'
import {
  getMenubarForVariant,
  getMenuForVariant,
  getToolbarForVariant,
  getStatusBarFeaturesForVariant,
  RCEVariant,
  type StatusBarOptions,
} from './RCEVariants'

import {
  focusFirstMenuButton,
  focusToolbar,
  isElementWithinTable,
  mergeMenu,
  mergeMenuItems,
  mergePlugins,
  mergeToolbar,
  parsePluginsToExclude,
  patchAutosavedContent,
} from './RCEWrapper.utils'
import {AlertMessage, EditorOptions, RCETrayProps} from './types'
import {externalToolsForToolbar} from './plugins/instructure_rce_external_tools/util/externalToolsForToolbar'
import {initScreenreaderOnFormat} from './screenreaderOnFormat'
import {normalizeContainingContext} from '../util/contextHelper'

const RestoreAutoSaveModal = React.lazy(() => import('./RestoreAutoSaveModal'))
const RceHtmlEditor = React.lazy(() => import('./RceHtmlEditor'))

const ASYNC_FOCUS_TIMEOUT = 250
const DEFAULT_RCE_HEIGHT = '400px'

function addKebabIcon(editor: TinyMCEEditor) {
  // This has to be done here instead of of in plugins/instructure-ui-icons/plugin.ts
  // presumably because the toolbar gets created before that plugin is loaded?
  editor.ui.registry.addIcon('more-drawer', IconMoreSolid.src)
}

// Get oxide the default skin injected into the DOM before the overrides loaded by themeable
let inserted = false
function injectTinySkin() {
  if (inserted) return
  inserted = true
  const style = document.createElement('style')
  style.setAttribute('data-skin', 'tiny oxide skin')
  style.appendChild(document.createTextNode(skinCSS))
  // there's CSS from discussions that turns the instui Selectors bold
  // and in classic quizzes that also mucks with padding
  style.appendChild(
    document.createTextNode(`
      #discussion-edit-view .rce-wrapper input[readonly] {font-weight: normal;}
      #quiz_edit_wrapper .rce-wrapper input[readonly] {font-weight: normal; padding-left: .75rem;}
    `),
  )

  const beforeMe =
    document.head.querySelector('style[data-glamor]') || // find instui's themeable stylesheet
    document.head.querySelector('style') || // find any stylesheet
    document.head.firstElementChild
  document.head.insertBefore(style, beforeMe)
}

const editorWrappers = new WeakMap()

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
function renderLoading() {
  return formatMessage('Loading')
}

let alertIdValue = 0

interface RCEWrapperProps {
  ai_text_tools?: boolean
  autosave?: {
    enabled?: boolean
    maxAge?: number
  }
  canvasOrigin: string
  defaultContent?: string
  editorOptions: EditorOptions
  editorView?: string
  features: Record<string, unknown>
  handleUnmount?: () => void
  instRecordDisabled?: boolean
  language?: string
  liveRegion?: HTMLElement | null | (() => HTMLElement | null | undefined)
  ltiToolFavorites?: string[]
  maxInitRenderedRCEs: number
  name?: string
  onBlur?: (event: React.FocusEvent<HTMLElement>) => void
  onContentChange?: (content: string) => void
  onFocus?: (rce: RCEWrapper) => void
  onInitted?: (editor: TinyMCEEditor) => void
  onRemove?: (arg1: RCEWrapper) => void
  readOnly?: boolean
  renderKBShortcutModal?: boolean
  textareaClassName?: string
  textareaId?: string
  tinymce: typeof tinymce
  trayProps: RCETrayProps
  use_rce_icon_maker?: boolean
  userCacheKey?: string
}

interface RCEWrapperState {
  a11yErrorsCount: number
  AIToolsOpen: boolean
  AITToolsFocusReturn: unknown
  alertId?: number
  announcement: string | null
  autoSavedContent: string
  confirmAutoSave: boolean
  editor: Editor
  editorView: string
  fullscreenState: {
    prevHeight: number
    isTinyFullscreen?: boolean
  }
  height: string
  id: string
  KBShortcutFocusReturn?: HTMLElement
  KBShortcutModalOpen: boolean
  messages: AlertMessage[]
  path: string[]
  shouldShowEditor: boolean
  shouldShowOnFocusButton: boolean
  wordCount: number
}

class RCEWrapper extends React.Component<RCEWrapperProps, RCEWrapperState> {
  _destroyCalled = false
  _editorPlaceholderRef: React.RefObject<HTMLElement>
  _elementRef: React.RefObject<HTMLElement>
  _focusRegio?: Element
  _focusRegion?: Element
  _mceSerializedInitialHtmlCached?: string | null
  _showOnFocusButton?: HTMLElement
  _statusBarId: string
  _textareaEl?: HTMLTextAreaElement
  _effectiveContainingContext: RCETrayProps['containingContext']
  AIToolsTray?: ReactNode
  editor: TinyMCEEditor | null
  initialContent?: string
  intersectionObserver?: IntersectionObserver
  language: string
  ltiToolFavorites: unknown[]
  mutationObserver?: MutationObserver
  pendingEventHandlers: Array<() => void>
  pluginsToExclude: string[]
  resizeObserver: ResizeObserver
  storage?: EncryptedStorage
  variant: RCEVariant
  style: {
    css: string
  }
  insert_code: typeof this.insertCode
  get_code: typeof this.getCode
  set_code: typeof this.setCode

  static getByEditor(editor: TinyMCEEditor) {
    return editorWrappers.get(editor)
  }

  static propTypes = rceWrapperPropTypes

  static defaultProps = {
    trayProps: null,
    autosave: {enabled: false},
    highContrastCSS: [],
    ltiTools: [],
    maxInitRenderedRCEs: -1,
    features: {},
    timezone: Intl?.DateTimeFormat()?.resolvedOptions()?.timeZone,
    canvasOrigin: '',
    variant: 'full',
  }

  static skinCssInjected = false

  constructor(props: RCEWrapperProps) {
    super(props)
    this.style = buildStyle()

    // Set up some limited global state that can be referenced
    // as needed in RCE's components and function / plugin definitions
    // Not intended to be dynamically changed!
    RCEGlobals.setFeatures(this.getRequiredFeatureStatuses())
    RCEGlobals.setConfig(this.getRequiredConfigValues())

    this.editor = null // my tinymce editor instance
    this.language = normalizeLocale(this.props.language)

    // interface consistent with editorBox
    this.get_code = this.getCode
    this.set_code = this.setCode
    this.insert_code = this.insertCode

    // test override points
    // @ts-expect-error
    this.indicator = false

    this._elementRef = React.createRef()
    this._editorPlaceholderRef = React.createRef()
    // @ts-expect-error
    this._prettyHtmlEditorRef = React.createRef()
    // @ts-expect-error
    this._showOnFocusButton = null

    // Process initial content
    // @ts-expect-error
    this.initialContent = this.getRequiredFeatureStatuses().rce_transform_loaded_content
      ? transformRceContentForEditing(this.props.defaultContent, {
          origin: this.props.canvasOrigin || window?.location?.origin,
        })
      : this.props.defaultContent

    injectTinySkin()

    // FWIW, for historic reaasons, the height does not include the
    // height of the status bar (which used to be tinymce's)
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
      // @ts-expect-error
      id: this.props.id || this.props.textareaId || `${uid('rce', 2)}`,
      // @ts-expect-error
      height: ht,
      fullscreenState: {
        // @ts-expect-error
        prevHeight: ht,
      },
      a11yErrorsCount: 0,
      shouldShowEditor:
        typeof IntersectionObserver === 'undefined' ||
        maxInitRenderedRCEs <= 0 ||
        currentRCECount < maxInitRenderedRCEs,
      AIToolsOpen: false,
    }
    this._statusBarId = `${this.state.id}_statusbar`

    this.pendingEventHandlers = []

    // @ts-expect-error
    this.ltiToolFavorites = externalToolsForToolbar(this.props.ltiTools).map(
      e => `instructure_external_button_${e.id}`,
    )

    this.pluginsToExclude = parsePluginsToExclude(props.editorOptions?.plugins || [])

    // @ts-expect-error
    this.resourceType = props.resourceType
    // @ts-expect-error
    this.resourceId = props.resourceId

    // @ts-expect-error
    this.variant = window.RCE_VARIANT || props.variant // to facilitate testing

    // @ts-expect-error
    this.tinymceInitOptions = this.wrapOptions(props.editorOptions)

    alertHandler.alertFunc = this.addAlert

    this.handleContentTrayClosing = this.handleContentTrayClosing.bind(this)

    this.resizeObserver = new ResizeObserver(() => {
      this._handleFullscreenResize()
    })

    this.AIToolsTray = undefined

    this._effectiveContainingContext = normalizeContainingContext(
      this.props.trayProps?.containingContext,
    )
  }

  // when the RCE is put into fullscreen we need to move the div
  // tinymce mounts popup menus into from the body to the rce-wrapper
  // or the menus wind up behind the RCE. I can't find a way to
  // configure tinymce to say where that div is mounted, do this
  // is a bit of a hack to tag the div that is this RCE's
  _tagTinymceAuxDiv() {
    const tinyauxlist = document.querySelectorAll('.tox-tinymce-aux')
    if (tinyauxlist.length) {
      const myaux = tinyauxlist[tinyauxlist.length - 1]
      if (myaux.id) {
        console.error('Unexpected ID on my tox-tinymce-aux element')
      }
      myaux.id = `tinyaux-${this.id}`
    }
  }

  _myTinymceAuxDiv() {
    return document.getElementById(`tinyaux-${this.id}`)
  }

  getRequiredFeatureStatuses() {
    const {
      new_math_equation_handling = false,
      explicit_latex_typesetting = false,
      rce_transform_loaded_content = false,
      rce_find_replace = false,
      file_verifiers_for_quiz_links = false,
      consolidated_media_player = false,
    } = this.props.features

    return {
      new_math_equation_handling,
      explicit_latex_typesetting,
      rce_transform_loaded_content,
      file_verifiers_for_quiz_links,
      rce_find_replace,
      consolidated_media_player,
    }
  }

  getRequiredConfigValues() {
    return {
      locale: normalizeLocale(this.props.language),
      // @ts-expect-error
      flashAlertTimeout: this.props.flashAlertTimeout,
      // @ts-expect-error
      timezone: this.props.timezone,
    }
  }

  getCanvasUrl() {
    return this.props.canvasOrigin
  }

  getResourceIdentifiers() {
    return {
      // @ts-expect-error
      resourceType: this.resourceType,
      // @ts-expect-error
      resourceId: this.resourceId,
    }
  }

  // getCode and setCode naming comes from tinyMCE
  // kind of strange but want to be consistent
  getCode() {
    return this.isHidden() ? this.textareaValue() : this.mceInstance().getContent()
  }

  // @ts-expect-error
  checkReadyToGetCode(promptFunc) {
    let status = true
    // Check for remaining placeholders
    if (this.mceInstance().dom.doc.querySelector(`[data-placeholder-for]`)) {
      status = promptFunc(
        formatMessage(
          'Content is still being uploaded, if you continue it will not be embedded properly.',
        ),
      )
    }

    return status
  }

  setCode(newContent: string) {
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

  indicateEditor(element: Element) {
    if (document.querySelector('[role="dialog"][data-mce-component]')) {
      // there is a modal open, which zeros out the vertical scroll
      // so the indicator is in the wrong place.  Give it a chance to close
      window.setTimeout(() => {
        this.indicateEditor(element)
      }, 100)
      return
    }
    const editor = this.mceInstance()
    // @ts-expect-error
    if (this.indicator) {
      // @ts-expect-error
      this.indicator(editor, element)
    } else if (!this.isHidden()) {
      indicate(indicatorRegion(editor, element))
    }
  }

  contentInserted(element: Element) {
    this.indicateEditor(element)
    this.checkImageLoadError(element)
    this.sizeEditorForContent(element)
  }

  // make a attempt at sizing the editor so that the new content fits.
  // works under the assumptions the body's box-sizing is not content-box
  // and that the content is w/in a <p> whose margin is 12px top and bottom
  // (which, in canvas, is set in app/stylesheets/components/_ic-typography.scss)
  sizeEditorForContent(elem: Element) {
    let height
    if (elem && elem.nodeType === 1) {
      height = elem.clientHeight
    }
    if (height) {
      const ifr = this.iframe
      if (ifr) {
        // @ts-expect-error
        const editor_body_style = ifr.contentWindow.getComputedStyle(
          // @ts-expect-error
          this.iframe.contentDocument.body,
        )
        const editor_ht =
          // @ts-expect-error
          ifr.contentDocument.body.clientHeight -
          // @ts-expect-error
          parseInt(editor_body_style['padding-top'], 10) -
          // @ts-expect-error
          parseInt(editor_body_style['padding-bottom'], 10)

        const para_margin_ht = 24
        const reserve_ht = Math.ceil(height + para_margin_ht)
        if (reserve_ht > editor_ht) {
          this.onResize(null, {deltaY: reserve_ht - editor_ht})
        }
      }
    }
  }

  checkImageLoadError(element: Element) {
    if (!element || element.tagName !== 'IMG') {
      return
    }
    // @ts-expect-error
    if (!element.complete) {
      // @ts-expect-error
      element.onload = () => this.checkImageLoadError(element)
      return
    }
    // checking naturalWidth in a future event loop run prevents a race
    // condition between the onload callback and naturalWidth being set.
    setTimeout(() => {
      // @ts-expect-error
      if (element.naturalWidth === 0) {
        // @ts-expect-error
        element.style.border = '1px solid #000'
        // @ts-expect-error
        element.style.padding = '2px'
      }
    }, 0)
  }

  insertCode(code: string) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertContent(editor, code)
    this.contentInserted(element)
  }

  replaceCode(code: string) {
    if (
      code !== '' &&
      window.confirm(
        formatMessage(
          'Content in the editor will be changed. Press Cancel to keep the original content.',
        ),
      )
    ) {
      this.mceInstance().setContent(code)
    }
  }

  insertEmbedCode(code: string) {
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

  insertImage(image: unknown) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertImage(editor, image, this.getCanvasUrl())

    // Removes TinyMCE's caret &nbsp; text if exists.
    if (element?.nextSibling?.data?.startsWith('\xA0' /* nbsp */)) {
      element.nextSibling.splitText(1)
      element.nextSibling.remove()
    }

    return {
      imageElem: element,
      loadingPromise: new Promise<void>((resolve, reject) => {
        if (element && element.complete) {
          this.contentInserted(element)
          resolve()
        } else if (element) {
          element.onload = () => {
            this.contentInserted(element)
            resolve()
          }
          element.onerror = (e: Error) => {
            this.checkImageLoadError(element)
            reject(e)
          }
        }
      }),
    }
  }

  insertImagePlaceholder(fileMetaProps: PlaceHoldableThingInfo) {
    return insertPlaceholder(
      this.mceInstance(),
      fileMetaProps.name,
      placeholderInfoFor(fileMetaProps),
    )
  }

  insertVideo(video: unknown) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertVideo(editor, video, this.getCanvasUrl())
    this.contentInserted(element)
  }

  insertAudio(audio: unknown) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertAudio(editor, audio, this.getCanvasUrl())
    this.contentInserted(element)
  }

  insertMathEquation(tex: unknown) {
    const editor = this.mceInstance()
    contentInsertion.insertEquation(editor, tex)
  }

  removePlaceholders(name: string) {
    removePlaceholder(this.mceInstance(), name)
  }

  insertLink(link: unknown) {
    const editor = this.mceInstance()
    const element = contentInsertion.insertLink(editor, link, this.getCanvasUrl())
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
  // @ts-expect-error
  tinymceOn(tinymceEventName, handler) {
    if (this.state.shouldShowEditor) {
      this.mceInstance().on(tinymceEventName, handler)
    } else {
      // @ts-expect-error
      this.pendingEventHandlers.push({name: tinymceEventName, handler})
    }
  }

  mceInstance() {
    if (this.editor) {
      return this.editor
    }
    return this.props.tinymce.get(this.props.textareaId!)!
  }

  // @ts-expect-error
  onTinyMCEInstance(command: string, ...args) {
    const editor = this.mceInstance()
    if (editor) {
      if (command === 'mceRemoveEditor') {
        editor.execCommand('mceNewDocument')
      } // makes sure content can't persist past removal
      editor.execCommand(command, false, ...args)
    }
  }

  destroy() {
    this._destroyCalled = true
    this.unhandleTextareaChange()
    if (this.props.handleUnmount) {
      this.props.handleUnmount()
    }
  }

  onRemove = () => {
    bridge.detachEditor(this)
    if (this.props.onRemove) {
      this.props.onRemove(this)
    }
  }

  getTextarea(): HTMLTextAreaElement | null {
    const node = this.props.textareaId && document.getElementById(this.props.textareaId)
    if (node instanceof HTMLTextAreaElement) {
      return node
    }
    return null
  }

  textareaValue() {
    return this.getTextarea()?.value || ''
  }

  get id() {
    return this.state.id
  }

  getHtmlEditorStorage() {
    const cookieValue = getCookie('rce.htmleditor')
    if (cookieValue) {
      document.cookie = `rce.htmleditor=${cookieValue};path=/;max-age=0`
    }
    const value = cookieValue || this.storage?.getItem?.('rce.htmleditor')?.content
    return value === RAW_HTML_EDITOR_VIEW || value === PRETTY_HTML_EDITOR_VIEW
      ? value
      : PRETTY_HTML_EDITOR_VIEW
  }

  toggleView = (newView: string) => {
    // coming from the menubar, we don't have a newView,

    let newState: Partial<RCEWrapperState>
    switch (this.state.editorView) {
      case WYSIWYG_VIEW: {
        newState = {editorView: newView || PRETTY_HTML_EDITOR_VIEW}
        break
      }
      case PRETTY_HTML_EDITOR_VIEW: {
        newState = {editorView: newView || WYSIWYG_VIEW}
        break
      }
      case RAW_HTML_EDITOR_VIEW: {
        newState = {editorView: newView || WYSIWYG_VIEW}
        break
      }
      default:
        return
    }
    // @ts-expect-error
    this.setState(newState)
    this.checkAccessibility()
    if (newView === PRETTY_HTML_EDITOR_VIEW || newView === RAW_HTML_EDITOR_VIEW) {
      this.storage?.setItem?.('rce.htmleditor', newView)
    }

    // Emit view change event
    this.mceInstance().fire(VIEW_CHANGE, {
      target: this.editor,
      newView: newState.editorView,
    })
  }

  toggleFullscreen = () => {
    this.handleClickFullscreen()
  }

  _isFullscreen() {
    return !!(this.state.fullscreenState.isTinyFullscreen || document[FS_ELEMENT])
  }

  _enterFullscreen() {
    // tinymce mounts its menus and toolbars in this element, which is in the DOM
    // at the bottom of the body. When we're fullscreen the menus need to be mounted
    // in the fullscreen element or they won't show up. Let's move tinymce's mount point
    // when we go into fullscreen, then put it back when we're finished.
    const tinymenuhost = this._myTinymceAuxDiv()
    if (tinymenuhost) {
      tinymenuhost.remove()
      this._elementRef.current?.appendChild(tinymenuhost)
    }

    this._elementRef.current?.addEventListener(FS_CHANGEEVENT, this._onFullscreenChange)
    if (typeof this._elementRef.current?.offsetHeight === 'number') {
      this.setState({
        fullscreenState: {
          prevHeight: this._elementRef.current.offsetHeight - this._getStatusBarHeight(),
        },
      })
    }
    // @ts-expect-error
    this._elementRef.current[FS_REQUEST]()
  }

  _exitFullscreen() {
    if (document[FS_ELEMENT]) {
      const tinymenuhost = this._myTinymceAuxDiv()
      if (tinymenuhost) {
        tinymenuhost.remove()
        document.body.appendChild(tinymenuhost)
      }
      document[FS_EXIT]()
    }
  }

  // @ts-expect-error
  _onFullscreenChange = event => {
    if (document[FS_ELEMENT]) {
      // @ts-expect-error
      this.resizeObserver.observe(document[FS_ELEMENT])
      window.visualViewport?.addEventListener('resize', this._handleFullscreenResize)
      this._handleFullscreenResize()
      // @ts-expect-error
      this._focusRegion = FocusRegionManager.activateRegion(document[FS_ELEMENT], {
        shouldContainFocus: true,
      })
    } else {
      event.target.removeEventListener(FS_CHANGEEVENT, this._onFullscreenChange)
      this.resizeObserver.unobserve(event.target)
      window.visualViewport?.removeEventListener('resize', this._handleFullscreenResize)
      this._setHeight(this.state.fullscreenState.prevHeight)
      if (this._focusRegion) {
        FocusRegionManager.blurRegion(event.target, this._focusRegion.id)
      }
    }
    this.focusCurrentView()
  }

  _handleFullscreenResize = () => {
    const ht = window.visualViewport?.height || document[FS_ELEMENT]?.offsetHeight
    this._setHeight((ht || 0) - this._getStatusBarHeight())
  }

  _getStatusBarHeight(): number {
    // the height prop is the height of the editor and does not include
    // the status bar. we'll need this later.
    const node = document.getElementById(this._statusBarId)
    return node?.offsetHeight || 0
  }

  _setHeight(newHeight: number) {
    const cssHeight = `${newHeight}px`
    const ed = this.mceInstance()
    const container = ed.getContainer()
    if (container) {
      container.style.height = cssHeight
      ed.fire('ResizeEditor')
    }
    const textarea = this.getTextarea()
    if (textarea) {
      textarea.style.height = cssHeight
    }
    this.setState({height: cssHeight})
  }

  focus() {
    this.onTinyMCEInstance('mceFocus')
    // tinymce doesn't always call the focus handler.
    // @ts-expect-error
    this.handleFocusEditor(new Event('focus', {target: this.mceInstance()}))
  }

  focusCurrentView() {
    switch (this.state.editorView) {
      case WYSIWYG_VIEW: {
        this.mceInstance().focus()
        break
      }
      case PRETTY_HTML_EDITOR_VIEW: {
        break
      }
      case RAW_HTML_EDITOR_VIEW: {
        const textarea = this.getTextarea()
        if (textarea) {
          textarea.focus()
        }
        break
      }
    }
  }

  is_dirty() {
    if (this.mceInstance().isDirty()) {
      return true
    }
    const currentHtml = this.isHidden() ? this.textareaValue() : this.mceInstance()?.getContent()
    return currentHtml !== this._mceSerializedInitialHtml
  }

  /**
   * Holds a copy of the initial content of the editor as serialized by tinyMCE to normalize it.
   */
  get _mceSerializedInitialHtml() {
    if (!this._mceSerializedInitialHtmlCached) {
      const el = window.document.createElement('div')
      // @ts-expect-error
      el.innerHTML = this.initialContent
      const serializer = this.mceInstance().serializer
      this._mceSerializedInitialHtmlCached = serializer.serialize(el, {
        getInner: true,
      })
    }
    return this._mceSerializedInitialHtmlCached
  }

  isHtmlView() {
    return this.state.editorView !== WYSIWYG_VIEW
  }

  isHidden() {
    return this.mceInstance().isHidden()
  }

  get iframe() {
    return document.getElementById(`${this.props.textareaId}_ifr`) as HTMLIFrameElement
  }

  // these focus and blur event handlers work together so that RCEWrapper
  // can report focus and blur events from the RCE at-large
  get focused() {
    return this === bridge.getEditor()
  }

  handleFocus() {
    if (!this.focused) {
      bridge.focusEditor(this)
      if (this.props.onFocus) {
        this.props.onFocus(this)
      }
    }
  }

  contentTrayClosing = false

  handleContentTrayClosing(isClosing: boolean) {
    this.contentTrayClosing = isClosing
  }

  blurTimer = 0

  handleBlur(event: React.FocusEvent<HTMLElement>) {
    if (this.blurTimer) return

    if (this.focused) {
      // because the old active element fires blur before the next element gets focus
      // we often need a moment to see if focus comes back
      // eslint-disable-next-line @typescript-eslint/no-unused-expressions
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
          // @ts-expect-error
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
        if (this.props.onBlur) {
          this.props.onBlur(event)
        }
      }, ASYNC_FOCUS_TIMEOUT)
    }
  }

  handleFocusRCE = () => {
    this.handleFocus()
  }

  // @ts-expect-error
  handleBlurRCE = event => {
    if (event.relatedTarget === null) {
      // focus might be moving to tinymce
      this.handleBlur(event)
    }

    if (!this._elementRef.current?.contains(event.relatedTarget)) {
      this.handleBlur(event)
    }
  }

  handleFocusEditor = (_event: Event) => {
    // use .active to put a focus ring around the content area
    // when the editor has focus. This isn't perfect, but it's
    // what we've got for now.
    const ifr = this.iframe
    if (ifr?.parentElement) {
      ifr.parentElement.classList.add('active')
    }

    this.handleFocus()
  }

  handleBlurEditor = (event: React.FocusEvent<HTMLElement>) => {
    const ifr = this.iframe
    if (ifr?.parentElement) {
      ifr.parentElement.classList.remove('active')
    }
    this.handleBlur(event)
  }

  // @ts-expect-error
  call(methodName: string, ...args) {
    // since exists? has a ? and cant be a regular function just return true
    // rather than calling as a fn on the editor
    if (methodName === 'exists?') {
      return true
    }
    // @ts-expect-error
    return this[methodName](...args)
  }

  handleKey = (event: KeyboardEvent) => {
    if (event.code === 'F9' && event.altKey) {
      event.preventDefault()
      event.stopPropagation()
      // @ts-expect-error
      focusFirstMenuButton(this._elementRef.current)
    } else if (event.code === 'F10' && event.altKey) {
      event.preventDefault()
      event.stopPropagation()
      // @ts-expect-error
      focusToolbar(this._elementRef.current)
    } else if (event.code === 'F8' && event.altKey) {
      event.preventDefault()
      event.stopPropagation()
      this.openKBShortcutModal()
    } else if (event.code === 'Escape') {
      bridge.hideTrays()
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

  handleInputChange = () => {
    this.checkAccessibility()
  }

  onInit = (_event: Event, editor: TinyMCEEditor) => {
    // @ts-expect-error
    editor.rceWrapper = this
    this.editor = editor
    const textarea = this.editor.getElement()

    // expected by canvas
    // @ts-expect-error
    textarea.dataset.rich_text = true

    // start with the textarea and tinymce in sync
    // @ts-expect-error
    textarea.value = this.getCode()
    textarea.style.height = this.state.height
    textarea.removeAttribute('aria-hidden')

    if (document.body.classList.contains('Underline-All-Links__enabled')) {
      if (this.iframe?.contentDocument) {
        this.iframe.contentDocument.body.classList.add('Underline-All-Links__enabled')
      }
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

    // Probably should do this in tinymce.scss, but we only want it in new rce
    textarea.style.resize = 'none'
    editor.on('keydown', this.handleKey)
    editor.on('FullscreenStateChanged', this._onFullscreenChange)
    // This propagates click events on the editor out of the iframe to the parent
    // document. We need this so that click events get captured properly by instui
    // focus-trapping components, so they properly ignore trapping focus on click.
    editor.on('click', () => window.document.body.click(), true)
    editor.on('Cut Change input Undo Redo', debounce(this.handleInputChange, 1000))
    initScreenreaderOnFormat(editor)
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
      this.iframe.setAttribute(
        'title',
        formatMessage('Rich Text Area. Press {OSKey}+F8 for Rich Content Editor shortcuts.', {
          OSKey: determineOSDependentKey(),
        }),
      )
    }

    this._setupSelectionSaving(editor)

    this.checkAccessibility()

    this.fixToolbarKeyboardNavigation()

    if (this.props.onInitted) {
      this.props.onInitted(editor)
    }

    // cleans up highlight artifacts from findreplace plugin
    if (this.getRequiredFeatureStatuses().rce_find_replace) {
      editor.on('undo redo', _e => {
        if (editor?.dom?.doc?.getElementsByClassName?.('mce-match-marker')?.length > 0) {
          editor.plugins?.searchreplace?.done()
        }
      })
    }
  }

  /**
   * Fix keyboard navigation in the expanded toolbar
   *
   * NOTE: This is a workaround for https://github.com/tinymce/tinymce/issues/8618
   *       and should be removed once that issue is resolved and the tinymce dependency is updated to include it.
   */
  fixToolbarKeyboardNavigation = () => {
    // The keyboard navigation config in tinymce for the expanded toolbar is incorrectly configured,
    // and stops at [data-alloy-tabstop] elements.
    // It should be configured to stop on .tox-toolbar__group elements.
    // This workaround removes attribute, thusly causing navigation to work correctly again.
    // For the correct solution, Keying.config should have { selector: '.tox-toolbar__group' }
    // in https://github.com/tinymce/tinymce/blob/develop/modules/alloy/src/main/ts/ephox/alloy/ui/schema/SplitSlidingToolbarSchema.ts
    this._elementRef.current
      ?.querySelectorAll('.tox-toolbar-overlord button[data-alloy-tabstop]')
      .forEach(it => it.removeAttribute('data-alloy-tabstop'))
  }

  /**
   * Sets up selection saving and restoration logic.
   *
   * There are certain actions a user can take when the RCE is not focused that clear the selection inside the
   * editor, such as invoking the Find feature of the browser. If the user then tries to insert content without
   * going back to the editor, the content would be inserted at the top of the RCE, instead of where their cursor
   * was.
   *
   * This method adds logic that saves and restores the selection to work around the issue.
   *
   * @private
   */
  // @ts-expect-error
  _setupSelectionSaving = editor => {
    // @ts-expect-error
    let savedSelection = null
    let selectionWasReset = false
    let editorHasFocus = false

    const restoreSelectionIfNecessary = () => {
      // @ts-expect-error
      if (this.editor && savedSelection && selectionWasReset) {
        this.editor.selection.setRng(savedSelection.range, savedSelection.isForward)
        selectionWasReset = false
      }
    }

    editor.on('blur', () => {
      editorHasFocus = false
      selectionWasReset = false
      if (!this.editor) return
      savedSelection = {
        range: this.editor.selection.getRng().cloneRange(),
        isForward: this.editor.selection.isForward(),
      }
    })

    editor.on('focus', () => {
      // We need to restore the selection when the editor regains focus because sometimes the editor regains
      // focus without the user setting the selection themselves (such as when they interact with the toolbar)
      // and if we didn't, we would end up saving the reset selection before a user managed to actually insert
      // content.
      restoreSelectionIfNecessary()

      editorHasFocus = true
      selectionWasReset = false
    })

    editor.on('SelectionChange', () => {
      if (editorHasFocus) {
        // We don't care if a selection reset occurs when the editor has focus, the user probably intended that
        // At least they will see the effect
        return
      }

      if (!this.editor) return
      const selection = this.editor.selection.normalize()

      // Detect a browser-reset selection (e.g. From invoking the Find command)
      if (
        selection.startContainer?.nodeName === 'BODY' &&
        selection.startContainer === selection.endContainer &&
        selection.startOffset === 0 &&
        selection.endOffset === 0
      ) {
        selectionWasReset = true
      }
    })

    editor.on('BeforeExecCommand', () => {
      restoreSelectionIfNecessary()
    })

    editor.on('ExecCommand', (/* event */) => {
      if (!this.editor) return
      // Commands may have modified the selection, we need to recapture it
      savedSelection = {
        range: this.editor.selection.getRng().cloneRange(),
        isForward: this.editor.selection.isForward(),
      }
    })
  }

  announcing = 0

  announceContextToolbars(editor: TinyMCEEditor) {
    editor.on('NodeChange', () => {
      const node = editor.selection.getNode()
      // @ts-expect-error
      if (isImageEmbed(node, editor)) {
        if (this.announcing !== 1) {
          this.setState({
            announcement: formatMessage('type Control F9 to access image options. {text}', {
              text: node.getAttribute('alt'),
            }),
          })
          this.announcing = 1
        }
      } else if (isFileLink(node, editor)) {
        if (this.announcing !== 2) {
          this.setState({
            announcement: formatMessage('type Control F9 to access link options. {text}', {
              text: node.textContent,
            }),
          })
          this.announcing = 2
        }
      } else if (isElementWithinTable(node)) {
        if (this.announcing !== 3) {
          this.setState({
            announcement: formatMessage('type Control F9 to access table options. {text}', {
              text: node.textContent,
            }),
          })
          this.announcing = 3
        }
      } else {
        this.setState({
          announcement: null,
        })
        this.announcing = 0
      }
    })

    editor.on('ResizeEditor', ({deltaY}) => {
      if (!deltaY) return
      if (deltaY < 0) {
        this.setState({
          announcement: formatMessage('The height of Rich Content Area is decreased.'),
        })
      } else {
        this.setState({
          announcement: formatMessage('The height of Rich Content Area is increased.'),
        })
      }
    })
  }

  /* ********** autosave support *************** */
  initAutoSave = (editor: TinyMCEEditor) => {
    this.storage = new EncryptedStorage(this.props.userCacheKey ?? '')
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
          const editorContent = patchAutosavedContent(editor.getContent({no_events: true}), true)
          const autosavedContent = patchAutosavedContent(autosaved.content, true)

          if (autosavedContent !== editorContent) {
            this.setState({
              confirmAutoSave: true,
              // @ts-expect-error
              autoSavedContent: patchAutosavedContent(autosaved.content),
            })
          } else {
            this.storage.removeItem(this.autoSaveKey)
          }
        }
      } catch (ex) {
        // log and ignore

        console.error('Failed initializing rce autosave', ex)
      }
    }
  }

  // remove any autosaved value that's too old

  cleanupAutoSave = (deleteAll = false) => {
    if (this.storage) {
      const expiry = deleteAll ? Date.now() : Date.now() - (this.props.autosave?.maxAge || 0)
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

  // @ts-expect-error
  restoreAutoSave = ans => {
    this.setState({confirmAutoSave: false}, () => {
      const editor = this.mceInstance()
      if (ans) {
        editor.setContent(this.state.autoSavedContent, {})
      }
      // @ts-expect-error
      this.storage.removeItem(this.autoSaveKey)
    })
    // let the content be restored
    debounce(this.checkAccessibility, 1000)()
  }

  getAutoSaved(key: string) {
    let autosaved = null
    try {
      autosaved = this.storage && this.storage.getItem(key)
    } catch (_ex) {
      // @ts-expect-error
      this.storage.removeItem(this.autoSaveKey)
    }
    return autosaved
  }

  // only autosave if the feature flag is set, and there is only 1 RCE on the page
  // the latter condition is necessary because the popup RestoreAutoSaveModal
  // is lousey UX when there are >1
  get isAutoSaving() {
    if (!this.editor) return false

    // If the editor is invisible for some reason, don't show the autosave modal
    // This doesn't apply if the editor is off-screen or has visibility:hidden;
    // only if it isn't rendered or has display:none;
    const editorVisible = this.editor.getContainer().offsetParent

    return (
      this.props.autosave?.enabled &&
      editorVisible &&
      document.querySelectorAll('.rce-wrapper').length === 1 &&
      storageAvailable()
    )
  }

  get autoSaveKey() {
    const userId = this._effectiveContainingContext?.userId || '-'
    return `rceautosave:${userId}${window.location.href}:${this.props.textareaId}`
  }

  // @ts-expect-error
  doAutoSave = (e, retry = false) => {
    if (this.storage) {
      const editor = this.mceInstance()
      // if the editor is empty don't save
      if (editor.dom.isEmpty(editor.getBody())) {
        return
      }

      const content = editor.getContent({no_events: true})
      try {
        this.storage.setItem(this.autoSaveKey, content)
      } catch (ex) {
        if (!retry) {
          // probably failed because there's not enough space
          // delete up all the other entries and try again
          this.cleanupAutoSave(true)
          this.doAutoSave(e, true)
        } else {
          console.error('Autosave failed:', ex)
        }
      }
    }
  }
  /* *********** end autosave support *************** */

  onWordCountUpdate = (e: {
    wordCount: {words: number}
  }) => {
    if (!this.editor) return
    const shouldIgnore = countShouldIgnore(this.editor, 'body', 'words')
    const updatedCount = e.wordCount.words - shouldIgnore
    this.setState(state => {
      if (updatedCount !== state.wordCount) {
        return {wordCount: updatedCount}
      } else return null
    })
  }

  // @ts-expect-error
  onNodeChange = e => {
    // This is basically copied out of the tinymce silver theme code for the status bar
    const path = e.parents
      .filter(
        (p: Element) =>
          p.nodeName !== 'BR' &&
          !p.getAttribute('data-mce-bogus') &&
          p.getAttribute('data-mce-type') !== 'bookmark',
      )
      // @ts-expect-error
      .map(p => p.nodeName.toLowerCase())
      .reverse()
    this.setState({path})
  }

  onEditorChange = (content: string, _editor: unknown) => {
    this.props.onContentChange?.(content)
    // check accessibility when clearing the editor,
    // all other times should be checked by handleInputChange
    if (content === '') {
      this.checkAccessibility()
    }
  }

  onResize = (_e: unknown, coordinates: {deltaY: number}) => {
    const editor = this.mceInstance()
    if (editor) {
      const container = editor.getContainer()
      if (!container) return
      const currentContainerHeight = Number.parseInt(container.style.height, 10)
      if (isNaN(currentContainerHeight)) return
      const modifiedHeight = currentContainerHeight + coordinates.deltaY
      const newHeight = `${modifiedHeight}px`
      container.style.height = newHeight
      const textarea = this.getTextarea()
      if (textarea) {
        textarea.style.height = newHeight
      }
      this.setState({height: newHeight})
      // play nice and send the same event that the silver theme would send
      editor.fire('ResizeEditor', {deltaY: coordinates.deltaY})
    }
  }

  onA11yChecker = (triggerElementId: string) => {
    const editor = this.mceInstance()
    editor.execCommand(
      'openAccessibilityChecker',
      false,
      {
        mountNode: instuiPopupMountNodeFn,
        triggerElementId,
        onFixError: (errors: Array<unknown>) => {
          this.setState({a11yErrorsCount: errors.length})
        },
      },
      {
        skip_focus: true,
      },
    )
  }

  checkAccessibility = () => {
    const editor = this.mceInstance()
    editor.execCommand(
      'checkAccessibility',
      false,
      {
        // @ts-expect-error
        done: errors => {
          this.setState({a11yErrorsCount: errors.length})
        },
      },
      {skip_focus: true},
    )
  }

  openKBShortcutModal = () => {
    this.setState({
      KBShortcutModalOpen: true,
      // @ts-expect-error
      KBShortcutFocusReturn: document.activeElement,
    })
  }

  closeKBShortcutModal = () => {
    this.setState({KBShortcutModalOpen: false})
  }

  KBShortcutModalExited = () => {
    if (this.state.KBShortcutFocusReturn === this.iframe) {
      // launched using a kb shortcut
      // the iframe has focus so we need to forward it on to tinymce editor
      if (this.editor) {
        this.editor.focus(false)
      }
    } else if (
      this.state.KBShortcutFocusReturn === document.getElementById(`show-on-focus-btn-${this.id}`)
    ) {
      // launched from showOnFocus button
      // edge case where focusing KBShortcutFocusReturn doesn't work
      this._showOnFocusButton?.focus()
    } else {
      // launched from kb shortcut button on status bar
      this.state.KBShortcutFocusReturn?.focus()
    }
  }

  handleAIClick = () => {
    import('./plugins/shared/ai_tools')
      .then(module => {
        // @ts-expect-error
        this.AIToolsTray = module.AIToolsTray

        this.setState({
          AIToolsOpen: true,
          AITToolsFocusReturn: document.activeElement,
        })
      })
      .catch(ex => {
        console.error('Failed loading the AIToolsTray', ex)
      })
  }

  closeAITools = () => {
    this.setState({AIToolsOpen: false})
  }

  AIToolsExited = () => {
    if (this.state.AITToolsFocusReturn === this.iframe) {
      // launched using a kb shortcut
      // the iframe has focus so we need to forward it on to tinymce editor
      if (this.editor) {
        this.editor.focus(false)
      }
    } else if (
      this.state.AITToolsFocusReturn === document.getElementById(`show-on-focus-btn-${this.id}`)
    ) {
      // launched from showOnFocus button
      // edge case where focusing KBShortcutFocusReturn doesn't work
      this._showOnFocusButton?.focus()
    } else {
      // launched from kb shortcut button on status bar
      // @ts-expect-error
      this.state.AITToolsFocusReturn?.focus()
    }
  }

  handleInsertAIContent = (content: string) => {
    const editor = this.mceInstance()
    contentInsertion.insertContent(editor, content)
  }

  handleReplaceAIContent = (content: string) => {
    const ed = this.mceInstance()
    const selection = ed.selection
    if (selection.getContent().length > 0) {
      selection.setContent(content)
    } else {
      ed.selection.select(ed.getBody(), true)
      selection.setContent(content)
    }
  }

  getCurrentContentForAI = () => {
    const selected = this.mceInstance().selection.getContent()
    return selected
      ? {
          type: 'selection',
          content: selected,
        }
      : {
          type: 'full',
          content: this.mceInstance().getContent(),
        }
  }

  componentWillUnmount() {
    if (this.state.shouldShowEditor) {
      window.clearTimeout(this.blurTimer)
      if (!this._destroyCalled) {
        this.destroy()
      }
      if (this._elementRef.current) {
        this._elementRef.current.removeEventListener('keydown', this.handleKey, true)
      }
      this.mutationObserver?.disconnect()
      this.intersectionObserver?.disconnect()
    }
  }

  wrapOptions(options = {}) {
    const rcsExists = !!(this.props.trayProps?.host && this.props.trayProps?.jwt)
    const userLocale = editorLanguage(this.language)

    // @ts-expect-error
    const setupCallback = options.setup

    const canvasPlugins = rcsExists
      ? ['instructure_image', 'instructure_documents', 'instructure_equation']
      : []

    if (rcsExists && !this.props.instRecordDisabled) {
      canvasPlugins.splice(2, 0, 'instructure_record')
    }

    const pastePlugins = rcsExists ? ['instructure_paste', 'paste'] : ['paste']

    if (
      rcsExists &&
      this.props.use_rce_icon_maker &&
      this.props.trayProps?.contextType === 'course'
    ) {
      canvasPlugins.push('instructure_icon_maker')
    }

    if (document[FS_ENABLED]) {
      canvasPlugins.push('instructure_fullscreen')
    }

    if (this.getRequiredFeatureStatuses().rce_find_replace) {
      canvasPlugins.push('searchreplace')
      canvasPlugins.push('instructure_search_and_replace')
    }

    const possibleNewMenubarItems = this.props.editorOptions.menu
      ? Object.keys(this.props.editorOptions.menu).join(' ')
      : undefined

    const wrappedOpts = {
      ...defaultTinymceConfig,
      ...options,

      readonly: this.props.readOnly,

      theme: 'silver', // some older code specified 'modern', which doesn't exist any more

      // @ts-expect-error
      height: options.height || DEFAULT_RCE_HEIGHT,

      language: userLocale,

      document_base_url: this.props.canvasOrigin,

      block_formats:
        // @ts-expect-error
        options.block_formats ||
        [
          `${formatMessage('Heading 2')}=h2`,
          `${formatMessage('Heading 3')}=h3`,
          `${formatMessage('Heading 4')}=h4`,
          `${formatMessage('Preformatted')}=pre`,
          `${formatMessage('Paragraph')}=p`,
        ].join('; '),

      setup: (editor: TinyMCEEditor) => {
        addKebabIcon(editor)
        editorWrappers.set(editor, this)
        const trayPropsWithColor = {
          // @ts-expect-error
          brandColor: this.style.theme.canvasBrandColor,
          ...this.props.trayProps,
        }
        bridge.trayProps?.set(editor, trayPropsWithColor)
        // @ts-expect-error
        bridge.userLocale = userLocale
        bridge.canvasOrigin = this.props.canvasOrigin
        if (typeof setupCallback === 'function') {
          setupCallback(editor)
        }
      },

      // Consumers can, and should!, still pass a content_css prop so that the content
      // in the editor matches the styles of the app it will be displayed in when saved.
      // This is just so we inject the helper class names that tinyMCE uses for
      // things like table resizing and stuff.
      // @ts-expect-error
      content_css: options.content_css || [],
      // @ts-expect-error
      content_style: contentCSS + (options.content_style || ''),

      menubar: mergeMenuItems(getMenubarForVariant(this.variant), possibleNewMenubarItems),

      // default menu options listed at https://www.tiny.cloud/docs/configure/editor-appearance/#menu
      // tinymce's default edit and table menus are fine
      // note: the tinymce paste command is used here instead of instructure_paste
      // since we currently can't effectively paste using the clipboard api anyway.
      // we include all the canvas specific items in the menu and toolbar
      // and rely on tinymce only showing them if the plugin is provided.
      // @ts-expect-error
      menu: mergeMenu(getMenuForVariant(this.variant), options.menu),

      toolbar: mergeToolbar(
        // @ts-expect-error
        getToolbarForVariant(this.variant, this.ltiToolFavorites),
        // @ts-expect-error
        options.toolbar,
      ),

      contextmenu: '', // show the browser's native context menu

      toolbar_mode: 'sliding',
      toolbar_sticky: true,

      // In regards to the ability to disable plugins:
      // we only have to explicitly manage the removal of plugins
      // here, i.e., we don't have to explicitly remove them from the
      // menu and toolbar merging. At this time, tinymce itself
      // handles all of that complexity. It that ever changes in the
      // future in an upgraded version, we will have to update the
      // logic in those other places as well.
      plugins: mergePlugins(
        [
          'autolink',
          'media',
          'table',
          'link',
          'directionality',
          'lists',
          'textpattern',
          'hr',
          'instructure_color',
          'instructure-ui-icons',
          'instructure_condensed_buttons',
          'instructure_links',
          'instructure_html_view',
          'instructure_media_embed',
          'a11y_checker',
          'wordcount',
          'instructure_wordcount',
          'instructure_studio_media_options',
          'instructure_rce_external_tools',
          ...pastePlugins,
          ...canvasPlugins,
        ],
        // filter out the plugins designated for removal
        // @ts-expect-error
        sanitizePlugins(options.plugins)?.filter(p => p.length > 0 && p[0] !== '-'),
        this.pluginsToExclude,
      ),
      textpattern_patterns: [
        {start: '* ', cmd: 'InsertUnorderedList'},
        {start: '- ', cmd: 'InsertUnorderedList'},
      ],
    }

    if (this.props.trayProps) {
      // @ts-expect-error
      wrappedOpts.canvas_rce_user_context = {
        type: this.props.trayProps.contextType,
        id: this.props.trayProps.contextId,
      }

      // @ts-expect-error
      wrappedOpts.canvas_rce_containing_context = {
        // @ts-expect-error
        type: this.props.trayProps.containingContext.contextType,
        // @ts-expect-error
        id: this.props.trayProps.containingContext.contextId,
      }
    }
    return wrappedOpts
  }

  handleTextareaChange = () => {
    if (this.isHidden()) {
      this.setCode(this.textareaValue())
      // @ts-expect-error
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
        {root: null, rootMargin: '200px 0px', threshold: 0.0},
      )
      // @ts-expect-error
      this.intersectionObserver.observe(this._editorPlaceholderRef.current)
    }
  }

  componentDidUpdate(prevProps: RCEWrapperProps, prevState: RCEWrapperState) {
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
      // @ts-expect-error
      myTiny.on(e.name, e.handler)
    })
    this._tagTinymceAuxDiv()
    this.registerTextareaChange()
    // @ts-expect-error
    this._elementRef.current.addEventListener('keydown', this.handleKey, true)
    // give the textarea its initial size
    this.onResize(null, {deltaY: 0})
    // Preload the LTI Tools modal
    // This helps with loading the favorited external tools
    if (this.ltiToolFavorites.length > 0) {
      import(
        './plugins/instructure_rce_external_tools/components/ExternalToolSelectionDialog/ExternalToolSelectionDialog'
      )
    }

    bridge.renderEditor(this)
  }

  // @ts-expect-error
  setEditorView(view) {
    switch (view) {
      case WYSIWYG_VIEW:
        this.setCode(this.textareaValue())
        this.mceInstance().show()
        break
      default:
        this.mceInstance().hide()
    }
  }

  addAlert = (alert: AlertMessage) => {
    alert.id = alertIdValue++
    this.setState(state => {
      let messages = state.messages.concat(alert)
      messages = _.uniqBy(messages, 'text') // Don't show the same message twice
      return {messages}
    })
  }

  removeAlert = (messageId: number) => {
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
              alignItems: 'center',
            }}
          >
            <Spinner renderTitle={renderLoading} size="medium" />
          </div>
        }
      >
        <View as="div" borderRadius="medium" borderWidth="small">
          <RceHtmlEditor
            // @ts-expect-error
            ref={this._prettyHtmlEditorRef}
            height={this.state.height}
            code={this.getCode()}
            onChange={value => {
              const node = this.getTextarea()
              if (node) {
                node.value = value
              }
              this.handleTextareaChange()
            }}
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
          // @ts-expect-error
          ref={this._editorPlaceholderRef}
          style={{
            height: `${this.props.editorOptions.height}px`,
            border: '1px solid grey',
          }}
        />
      )
    }
    const statusBarOptions: StatusBarOptions = {
      aiTextTools: this.props.ai_text_tools,
      isDesktop: tinymce.Env.deviceType.isDesktop(),
      a11yResizers: !!this.props.features?.rce_a11y_resize,
    }
    const statusBarFeatures = getStatusBarFeaturesForVariant(this.variant, statusBarOptions)
    return (
      <>
        <style>{this.style.css}</style>
        <StoreProvider
          jwt={this.props.trayProps?.jwt}
          refreshToken={this.props.trayProps?.refreshToken}
          host={this.props.trayProps?.host}
          contextType={this.props.trayProps?.contextType}
          contextId={this.props.trayProps?.contextId}
          canvasOrigin={this.props.canvasOrigin}
        >
          {/* @ts-expect-error */}
          {storeProps => {
            return (
              <div
                key={this.id}
                // @ts-expect-error
                className={`${this.style.classNames.root} rce-wrapper`}
                // @ts-expect-error
                ref={this._elementRef}
                style={this.variant === 'full' ? {marginBottom: '.5rem'} : undefined}
                onFocus={this.handleFocusRCE}
                onBlur={this.handleBlurRCE}
              >
                {this.state.shouldShowOnFocusButton && tinymce.Env.deviceType.isDesktop() && (
                  <ShowOnFocusButton
                    id={`show-on-focus-btn-${this.id}`}
                    onClick={this.openKBShortcutModal}
                    margin="xx-small"
                    screenReaderLabel={formatMessage('View keyboard shortcuts')}
                    // @ts-expect-error
                    ref={el => (this._showOnFocusButton = el)}
                  >
                    <IconKeyboardShortcutsLine />
                  </ShowOnFocusButton>
                )}
                <AlertMessageArea
                  messages={this.state.messages}
                  // @ts-expect-error
                  liveRegion={this.props.liveRegion}
                  afterDismiss={this.removeAlert}
                />
                {this.state.editorView === PRETTY_HTML_EDITOR_VIEW && this.renderHtmlEditor()}
                <div
                  style={{
                    display: this.state.editorView === PRETTY_HTML_EDITOR_VIEW ? 'none' : 'block',
                  }}
                >
                  <Editor
                    id={mceProps.textareaId}
                    textareaName={mceProps.name}
                    // @ts-expect-error
                    init={this.tinymceInitOptions}
                    initialValue={this.initialContent}
                    // @ts-expect-error
                    onInit={this.onInit}
                    onClick={this.handleFocusEditor}
                    onKeypress={this.handleFocusEditor}
                    // @ts-expect-error
                    onActivate={this.handleFocusEditor}
                    onRemove={this.onRemove}
                    // @ts-expect-error
                    onFocus={this.handleFocusEditor}
                    // @ts-expect-error
                    onBlur={this.handleBlurEditor}
                    onNodeChange={this.onNodeChange}
                    onEditorChange={this.onEditorChange}
                    liveRegion={this.props.liveRegion}
                  />
                </div>
                {statusBarFeatures.length > 0 && (
                  <StatusBar
                    id={this._statusBarId}
                    rceIsFullscreen={this._isFullscreen()}
                    readOnly={this.props.readOnly}
                    onChangeView={newView => this.toggleView(newView)}
                    path={this.state.path}
                    wordCount={this.state.wordCount}
                    editorView={this.state.editorView}
                    preferredHtmlEditor={this.getHtmlEditorStorage()}
                    onResize={this.onResize}
                    onKBShortcutModalOpen={this.openKBShortcutModal}
                    onA11yChecker={this.onA11yChecker}
                    onFullscreen={this.handleClickFullscreen}
                    // @ts-expect-error
                    a11yBadgeColor={this.style.theme.canvasBadgeBackgroundColor}
                    a11yErrorsCount={this.state.a11yErrorsCount}
                    onWordcountModalOpen={() =>
                      launchWordcountModal(this.mceInstance(), document, {
                        skipEditorFocus: true,
                      })
                    }
                    disabledPlugins={this.pluginsToExclude}
                    features={statusBarFeatures}
                    onAI={this.handleAIClick}
                  />
                )}
                {this._effectiveContainingContext && (
                  <CanvasContentTray
                    mountNode={instuiPopupMountNodeFn}
                    key={this.id}
                    canvasOrigin={this.getCanvasUrl()}
                    bridge={bridge}
                    editor={this}
                    onTrayClosing={this.handleContentTrayClosing}
                    use_rce_icon_maker={this.props.use_rce_icon_maker}
                    {...trayProps}
                    containingContext={this._effectiveContainingContext}
                    // @ts-expect-error
                    storeProps={storeProps}
                  />
                )}
                <KeyboardShortcutModal
                  onExited={this.KBShortcutModalExited}
                  onDismiss={this.closeKBShortcutModal}
                  open={this.state.KBShortcutModalOpen}
                />
                {this.props.ai_text_tools && this.AIToolsTray && (
                  // @ts-expect-error
                  <this.AIToolsTray
                    open={this.state.AIToolsOpen}
                    container={document.querySelector('[role="main"]')}
                    mountNode={instuiPopupMountNodeFn}
                    contextId={trayProps.contextId}
                    contextType={trayProps.contextId}
                    currentContent={this.getCurrentContentForAI()}
                    onClose={this.closeAITools}
                    onInsertContent={this.handleInsertAIContent}
                    onReplaceContent={this.handleReplaceAIContent}
                  />
                )}
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
                {/* @ts-expect-error */}
                <Alert screenReaderOnly={true} liveRegion={this.props.liveRegion}>
                  {this.state.announcement}
                </Alert>
              </div>
            )
          }}
        </StoreProvider>
      </>
    )
  }
}

export default RCEWrapper
export {mergeMenuItems, mergeMenu, mergeToolbar, mergePlugins, parsePluginsToExclude}
