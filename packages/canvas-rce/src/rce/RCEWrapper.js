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
import TinyMCE from "react-tinymce";

import formatMessage from "../format-message";
import * as contentInsertion from "./contentInsertion";
import indicatorRegion from "./indicatorRegion";
import indicate from "../common/indicate";
import Bridge from "../bridge";
import CanvasContentTray, {trayProps} from './plugins/shared/CanvasContentTray'
import StatusBar from './StatusBar';

import themeable from '@instructure/ui-themeable/lib'
import styles from '../skins/skin-delta.css'
import theme from '../skins/theme'

// Get oxide the default skin injected into the DOM before the overrides loaded by themeable
import {template} from '../../node_modules/tinymce/skins/ui/oxide/skin.min.css'
let inserted = false
function injectTinySkin() {
  if (inserted) return
  inserted = true
  const style = document.createElement("style");
  style.setAttribute('data-skin', 'tiny oxide skin')
  style.appendChild(
    // the .replace here is because the ui-themeable babel hook adds that prefix to all the class names
    document.createTextNode(template().replace(/tinymce__oxide--/g, ""))
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
  }

  // getCode and setCode naming comes from tinyMCE
  // kind of strange but want to be consistent
  getCode() {
    return this.isHidden()
      ? this.textareaValue()
      : this.mceInstance().getContent();
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
      this.setCode(this.textareaValue());
      this.getTextarea().setAttribute('aria-hidden', true);
    } else {
      this.getTextarea().removeAttribute('aria-hidden');
    }
    this.onTinyMCEInstance("mceToggleEditor");
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

    // use .active to put a focus ring around the content area
    // then the editor has focus. This isn't prefect, but it's
    // what we've got for now.
    const ifr = this.iframe
    ifr && ifr.parentElement.classList.add('active')

    this.props.onFocus && this.props.onFocus(this);
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

  annotateEditor(_e, editor) {
    editor.rceWrapper = this;
  }

  onInit(_e, editor) {
    initKeyboardShortcuts(this._elementRef, editor)
    if(document.body.classList.contains('Underline-All-Links__enabled')) {
      this.iframe.contentDocument.body.classList.add('Underline-All-Links__enabled')
    }
  }

  componentWillUnmount() {
    if (!this._destroyCalled) {
      this.destroy();
    }
  }

  wrapOptions(options = {}) {
    const setupCallback = options.setup;

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
        editorWrappers.set(editor, this);
        Bridge.trayProps.set(editor, this.props.trayProps)
        if (typeof setupCallback === "function") {
          setupCallback(editor);
        }
      },

      toolbar: [
        'fontsizeselect formatselect | bold italic underline forecolor backcolor superscript ' +
        'subscript | align bullist outdent indent | ' +
        'instructure_links instructure_image instructure_record | ' +
        'removeformat table instructure_equation instructure_equella'
      ],
      contextmenu: '',  // show the browser's native context menu

      toolbar_drawer: 'floating'
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
      this._textareaEl = el;
    }
  }

  componentDidMount() {
    this.registerTextareaChange();
  }

  componentDidUpdate() {
    this.registerTextareaChange();
  }

  render() {
    const {trayProps, ...mceProps} = this.props
    mceProps.editorOptions.statusbar = false

    return (
      <div ref={el => this._elementRef = el} className={styles.root}>
        <TinyMCE
          id={mceProps.textareaId}
          tinymce={mceProps.tinymce}
          className={mceProps.textareaClassName}
          onPreInit={this.annotateEditor.bind(this)}
          onInit={this.onInit.bind(this)}
          onClick={this.onFocus.bind(this)}
          onKeypress={this.onFocus.bind(this)}
          onActivate={this.onFocus.bind(this)}
          onRemove={this.onRemove.bind(this)}
          onBlur={this.onBlur.bind(this)}
          content={mceProps.defaultContent}
          config={this.wrapOptions(mceProps.editorOptions)}
        />

        <StatusBar onToggleHtml={this.toggle} />
        <CanvasContentTray bridge={Bridge} {...trayProps} />
      </div>
    );
  }
}

export default RCEWrapper