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

import PropTypes from "prop-types";
import React from "react";
import {Editor} from "@tinymce/tinymce-react";

import themeable from '@instructure/ui-themeable'
import {IconKeyboardShortcutsLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y'

import formatMessage from "../format-message";
import * as contentInsertion from "./contentInsertion";
import indicatorRegion from "./indicatorRegion";
import indicate from "../common/indicate";
import Bridge from "../bridge";
import CanvasContentTray, {trayProps} from './plugins/shared/CanvasContentTray'
import StatusBar from './StatusBar';
import ShowOnFocusButton from './ShowOnFocusButton'
import theme from '../skins/theme'
import {isImage} from './plugins/shared/fileTypeUtils'
import KeyboardShortcutModal from './KeyboardShortcutModal'


// we  `require` instead of `import` these 2 css files because the ui-themeable babel require hook only works with `require`
const styles = require('../skins/skin-delta.css')
const skinCSS = require('../../node_modules/tinymce/skins/ui/oxide/skin.min.css').template().replace(/tinymce__oxide--/g, "")
const contentCSS = require('../../node_modules/tinymce/skins/ui/oxide/content.css').template().replace(/tinymce__oxide--/g, "")

// If we ever get our jest tests configured so they can handle importing real esModules,
// we can move this to plugins/instructure-ui-icons/plugin.js like the rest.
function addKebabIcon(editor) {
  editor.ui.registry.addIcon('more-drawer', `
    <svg viewBox="0 0 1920 1920">
      <path d="M1129.412 1637.647c0 93.448-75.964 169.412-169.412 169.412-93.448 0-169.412-75.964-169.412-169.412 0-93.447 75.964-169.412 169.412-169.412 93.448 0 169.412 75.965 169.412 169.412zm0-677.647c0 93.448-75.964 169.412-169.412 169.412-93.448 0-169.412-75.964-169.412-169.412 0-93.448 75.964-169.412 169.412-169.412 93.448 0 169.412 75.964 169.412 169.412zm0-677.647c0 93.447-75.964 169.412-169.412 169.412-93.448 0-169.412-75.965-169.412-169.412 0-93.448 75.964-169.412 169.412-169.412 93.448 0 169.412 75.964 169.412 169.412z" stroke="none" stroke-width="1" fill-rule="evenodd"/>
    </svg>
  `)
}

// Get oxide the default skin injected into the DOM before the overrides loaded by themeable
let inserted = false
function injectTinySkin() {
  if (inserted) return
  inserted = true
  const style = document.createElement("style");
  style.setAttribute('data-skin', 'tiny oxide skin')
  style.appendChild(
    // the .replace here is because the ui-themeable babel hook adds that prefix to all the class names
    document.createTextNode(skinCSS)
  );
  const beforeMe =
    document.head.querySelector('style[data-glamor]') || // find instui's themeable stylesheet
    document.head.querySelector('style') || // find any stylesheet
    document.head.firstElementChild
  document.head.insertBefore(style, beforeMe);
}

const editorWrappers = new WeakMap();

function showMenubar(el, show) {
  const $menubar = el.querySelector('.tox-menubar')
  $menubar && ($menubar.style.display = show ? '' : 'none')
  if (show) {
    focusFirstMenuButton(el)
  }
}

function focusToolbar(el) {
  const $firstToolbarButton = el.querySelector('.tox-tbtn')
  $firstToolbarButton  && $firstToolbarButton.focus()
}

function focusFirstMenuButton(el) {
  const $firstMenu = el.querySelector('.tox-mbtn')
  $firstMenu && $firstMenu.focus()
}

function initKeyboardShortcuts(el, editor) {
  // hide the menubar
  showMenubar(el, false)

  // when typed w/in the editor's edit area
  editor.addShortcut('Alt+F9', '', () => {
    showMenubar(el, true)
  })
  // when typed somewhere else w/in RCEWrapper
  el.addEventListener('keyup', e => {
    if (e.altKey && e.code === 'F9') {
      showMenubar(el, true)
    }
  })

  // toolbar help
  el.addEventListener('keyup', e => {
    if (e.altKey && e.code === 'F10') {
      focusToolbar(el)
    }
  })
}

@themeable(theme, styles)
class RCEWrapper extends React.Component {
  static getByEditor(editor) {
    return editorWrappers.get(editor);
  }

  static propTypes = {
    confirmFunc: PropTypes.func,
    defaultContent: PropTypes.string,
    editorOptions: PropTypes.object,
    handleUnmount: PropTypes.func,
    language: PropTypes.string,
    onFocus: PropTypes.func,
    onRemove: PropTypes.func,
    textareaClassName: PropTypes.string,
    textareaId: PropTypes.string,
    tinymce: PropTypes.object,
    trayProps
  };

  static defaultProps = {
    trayProps: null
  }

  static skinCssInjected = false

  constructor(props) {
    super(props);

    // interface consistent with editorBox
    this.get_code = this.getCode;
    this.set_code = this.setCode;
    this.insert_code = this.insertCode;

    // test override points
    this.indicator = false;

    this._elementRef = null;

    injectTinySkin()

    this.state = {
      path: [],
      wordCount: 0,
      isHtmlView: false,
      KBShortcutModalOpen: false
    }
  }

  // getCode and setCode naming comes from tinyMCE
  // kind of strange but want to be consistent
  getCode() {
    return this.isHidden()
      ? this.textareaValue()
      : this.mceInstance().getContent();
  }

  checkReadyToGetCode(promptFunc) {
    let status = true;
    // Check for remaining placeholders
    if (this.mceInstance().dom.doc.querySelector(`[data-placeholder-for]`)) {
      status = promptFunc(formatMessage('An image is still being uploaded, if you continue the image will not be embedded properly.'))
    }

    return status;
  }

  setCode(newContent) {
    this.mceInstance().setContent(newContent);
  }

  indicateEditor(element) {
    const editor = this.mceInstance();
    if (this.indicator) {
      this.indicator(editor, element);
    } else if (!this.isHidden()) {
      indicate(indicatorRegion(editor, element));
    }
  }

  contentInserted(element) {
    this.indicateEditor(element);
    this.checkImageLoadError(element);
  }

  checkImageLoadError(element) {
    if (!element || element.tagName !== "IMG") {
      return;
    }
    if (!element.complete) {
      element.onload = () => this.checkImageLoadError(element);
      return;
    }
    // checking naturalWidth in a future event loop run prevents a race
    // condition between the onload callback and naturalWidth being set.
    setTimeout(() => {
      if (element.naturalWidth === 0) {
        element.style.border = "1px solid #000";
        element.style.padding = "2px";
      }
    }, 0);
  }

  insertCode(code) {
    const editor = this.mceInstance();
    const element = contentInsertion.insertContent(editor, code);
    this.contentInserted(element);
  }

  insertImage(image) {
    const editor = this.mceInstance();
    const element = contentInsertion.insertImage(editor, image);
    if (element && element.complete) {
      this.contentInserted(element);
    } else if (element) {
      element.onload = () => this.contentInserted(element);
      element.onerror = () => this.checkImageLoadError(element);
    }
  }

  insertImagePlaceholder(fileMetaProps) {
    let width, height;
    if (isImage(fileMetaProps.contentType)) {
      const image = new Image();
      image.src = fileMetaProps.domObject.preview
      width = `${image.width}px`
      height = `${image.height}px`
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
    />`;

    this.insertCode(markup);
  }

  removePlaceholders(name) {
    const placeholder = this.mceInstance().dom.doc.querySelector(`[data-placeholder-for="${name}"]`)
    if (placeholder) {
      placeholder.remove();
    }
  }

  insertLink(link) {
    const editor = this.mceInstance();
    const element = contentInsertion.insertLink(editor, link);
    this.contentInserted(element);
  }

  existingContentToLink() {
    const editor = this.mceInstance();
    return contentInsertion.existingContentToLink(editor);
  }

  existingContentToLinkIsImg() {
    const editor = this.mceInstance();
    return contentInsertion.existingContentToLinkIsImg(editor);
  }

  mceInstance() {
    const editors = this.props.tinymce.editors || [];
    return editors.filter(ed => ed.id === this.props.textareaId)[0];
  }

  onTinyMCEInstance(command) {
    if (command == "mceRemoveEditor") {
      let editor = this.mceInstance();
      if (editor) {
        editor.execCommand("mceNewDocument");
      } // makes sure content can't persist past removal
    }
    this.props.tinymce.execCommand(command, false, this.props.textareaId);
  }

  destroy() {
    this._destroyCalled = true;
    this.onTinyMCEInstance("mceRemoveEditor");
    this.unhandleTextareaChange();
    this.props.handleUnmount && this.props.handleUnmount();
  }

  onRemove() {
    Bridge.detachEditor(this);
    this.props.onRemove && this.props.onRemove(this);
  }

  getTextarea() {
    return document.getElementById(this.props.textareaId);
  }

  textareaValue() {
    return this.getTextarea().value;
  }

  toggle = () => {
    if (this.isHidden()) {
      this.setState({isHtmlView: false})
    } else {
      this.setState({isHtmlView: true})
    }
  }

  focus() {
    this.onTinyMCEInstance("mceFocus");
  }

  is_dirty() {
    const content = this.isHidden()
      ? this.textareaValue()
      : this.mceInstance().getContent();
    return content !== this.cleanInitialContent();
  }

  cleanInitialContent() {
    if (!this._cleanInitialContent) {
      const el = window.document.createElement("div");
      el.innerHTML = this.props.defaultContent;
      const serializer = this.mceInstance().serializer;
      this._cleanInitialContent = serializer.serialize(el, { getInner: true });
    }
    return this._cleanInitialContent;
  }

  isHidden() {
    return this.mceInstance().isHidden();
  }

  get iframe() {
    return document.getElementById(`${this.props.textareaId}_ifr`)
  }

  onFocus() {
    Bridge.focusEditor(this);

    this.props.onFocus && this.props.onFocus(this);
  }

  reallyOnFocus() {
    // use .active to put a focus ring around the content area
    // when the editor has focus. This isn't perfect, but it's
    // what we've got for now.
    const ifr = this.iframe
    ifr && ifr.parentElement.classList.add('active')

    this.onFocus()
  }

  onBlur() {
    const ifr = this.iframe
    ifr && ifr.parentElement.classList.remove('active')
  }

  call(methodName, ...args) {
    // since exists? has a ? and cant be a regular function just return true
    // rather than calling as a fn on the editor
    if (methodName === "exists?") {
      return true;
    }
    return this[methodName](...args);
  }

  onInit(_e, editor) {
    editor.rceWrapper = this;
    initKeyboardShortcuts(this._elementRef, editor)
    if(document.body.classList.contains('Underline-All-Links__enabled')) {
      this.iframe.contentDocument.body.classList.add('Underline-All-Links__enabled')
    }
    editor.on('wordCountUpdate', this.onWordCountUpdate)
    // and an aria-label to the application div that wraps RCE
    const tinyapp = document.querySelector('.tox-tinymce[role="application"]')
    if (tinyapp) {
      tinyapp.setAttribute('aria-label', formatMessage("Rich Content Editor"))
    }
    // Probably should do this in tinymce.scss, but we only want it in new rce
    this.getTextarea().style.resize = 'none'
    editor.on('KeyDown', this.handleShortcutKeyShortcut) // keyUp puts the char in the editor

    editor.on('Change', this.doAutoResize)
  }

  doAutoResize = (e) => {
    const contentElm = this.iframe.contentDocument.documentElement
    if (contentElm.scrollHeight > contentElm.clientHeight) {
      this.onResize(e, {deltaY: contentElm.scrollHeight - contentElm.clientHeight})
    }
  }

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
    const container = this.mceInstance().getContainer()
    const currentContainerHeight = Number.parseInt(container.style.height, 10)
    if (isNaN(currentContainerHeight)) return
    const modifiedHeight = currentContainerHeight + coordinates.deltaY
    const newHeight = `${modifiedHeight}px`
    container.style.height = newHeight
    this.getTextarea().style.height = newHeight
    // play nice and send the same event that the silver theme would send
    this.mceInstance().fire('ResizeEditor')
  }

  onA11yChecker = () => {
    this.onTinyMCEInstance('openAccessibilityChecker')
  }

  handleShortcutKeyShortcut = (event) => {
    if (event.altKey && (event.keyCode === 48 || event.keyCode === 119)) {
      event.preventDefault()
      event.stopPropagation()
      this.openKBShortcutModal()
    }
  }

  openKBShortcutModal = () => {
    this.setState({KBShortcutModalOpen: true})
  }

  closeKBShortcutModal = () => {
    this.setState({KBShortcutModalOpen: false})
  }

  KBShortcutModalClosed = () => {
    if(Bridge.activeEditor() === this) {
      this.onTinyMCEInstance('mceFocus')
    }
  }

  componentWillUnmount() {
    if (!this._destroyCalled) {
      this.destroy();
    }
    this._elementRef.removeEventListener('keyup', this.handleShortcutKeyShortcut, true)
  }

  wrapOptions(options = {}) {
    const setupCallback = options.setup;
    options.toolbar = options.toolbar || []
    const lti_tool_dropdown = options.toolbar.some(str => str.includes('lti_tool_dropdown')) ?
      'lti_tool_dropdown' :
      ''
    return {
      ...options,

      block_formats: [
        `${formatMessage('Header')}=h2`,
        `${formatMessage('Subheader')}=h3`,
        `${formatMessage('Small header')}=h4`,
        `${formatMessage('Preformatted')}=pre`,
        `${formatMessage('Paragraph')}=p`
      ].join('; '),

      setup: editor => {
        addKebabIcon(editor)
        editorWrappers.set(editor, this);
        const trayPropsWithColor = {brandColor: this.theme.canvasBrandColor, ...this.props.trayProps}
        Bridge.trayProps.set(editor, trayPropsWithColor)
        if (typeof setupCallback === "function") {
          setupCallback(editor);
        }
      },

      // Consumers can, and should!, still pass a content_css prop so that the content
      // in the editor matches the styles of the app it will be displayed in when saved.
      // This is just so we inject the helper class names that tinyMCE uses for
      // things like table resizing and stuff.
      content_style: contentCSS,

      toolbar: [
        'fontsizeselect formatselect | bold italic underline forecolor backcolor superscript ' +
        'subscript | align bullist outdent indent directionality | ' +
        'instructure_links instructure_image instructure_record instructure_documents | ' +
        `removeformat table instructure_equation ${lti_tool_dropdown}` // instructure_equella
      ],
      contextmenu: '',  // show the browser's native context menu

      toolbar_drawer: 'floating',

      // tiny's external link create/edit dialog config
      target_list: false,  // don't show the target list when creating/editing links
      link_title: false,   // don't show the title input when creating/editing links
      default_link_target: '_blank'
    }
  }

  handleTextareaChange = () => {
    if (this.isHidden()) {
      this.setCode(this.textareaValue());
    }
  };

  unhandleTextareaChange() {
    if (this._textareaEl) {
      this._textareaEl.removeEventListener("change", this.handleTextareaChange);
    }
  }

  registerTextareaChange() {
    const el = this.getTextarea();
    if (this._textareaEl !== el) {
      this.unhandleTextareaChange();
      el.addEventListener("change", this.handleTextareaChange);
      if (this.props.textareaClassName) {
        el.classList.add(this.props.textareaClassName)
      }
      this._textareaEl = el;
    }
  }

  componentDidMount() {
    this.registerTextareaChange();
    this._elementRef.addEventListener('keyup', this.handleShortcutKeyShortcut, true)
  }

  componentDidUpdate(_prevProps, prevState) {
    const {...mceProps} = this.props
    this.registerTextareaChange();
    if(prevState.isHtmlView !== this.state.isHtmlView) {
      if (this.state.isHtmlView) {
        this.getTextarea().removeAttribute('aria-hidden');
        this.mceInstance().hide()
        document.getElementById(mceProps.textareaId).focus()
      } else {
        this.setCode(this.textareaValue());
        this.getTextarea().setAttribute('aria-hidden', true);
        this.mceInstance().show()
        this.mceInstance().focus()
        this.doAutoResize()
      }
    }
  }

  render() {
    const {trayProps, ...mceProps} = this.props
    mceProps.editorOptions.statusbar = false

    return (
      <div ref={el => this._elementRef = el} className={styles.root}>
        <ShowOnFocusButton
          buttonProps={{
            variant: 'link',
            onClick: this.openKBShortcutModal,
            icon: IconKeyboardShortcutsLine,
            margin: 'xx-small'
          }}
        >
          {<ScreenReaderContent>{formatMessage('View keyboard shortcuts')}</ScreenReaderContent>}
        </ShowOnFocusButton>
        <Editor
          id={mceProps.textareaId}
          textareaName={mceProps.name}
          init={this.wrapOptions(mceProps.editorOptions)}
          initialValue={mceProps.defaultContent}
          onInit={this.onInit.bind(this)}
          onClick={this.onFocus.bind(this)}
          onKeypress={this.onFocus.bind(this)}
          onActivate={this.onFocus.bind(this)}
          onRemove={this.onRemove.bind(this)}
          onFocus={this.reallyOnFocus.bind(this)}
          onBlur={this.onBlur.bind(this)}
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
        <CanvasContentTray bridge={Bridge} {...trayProps} />
        <KeyboardShortcutModal
          onClose={this.KBShortcutModalClosed}
          onDismiss={this.closeKBShortcutModal}
          open={this.state.KBShortcutModalOpen}
        />
      </div>
    );
  }
}

export default RCEWrapper

