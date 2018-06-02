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

import React from "react";
import ReactDOM from "react-dom";
import TinyMCE from "react-tinymce";
import editorAccessibility from "./editorAccessibility";
import * as contentInsertion from "./contentInsertion";
import indicatorRegion from "./indicatorRegion";
import indicate from "../common/indicate";
import Bridge from "../bridge";

const editorWrappers = new WeakMap();

export default class RCEWrapper extends React.Component {
  static getByEditor(editor) {
    return editorWrappers.get(editor);
  }

  constructor(props) {
    super(props);

    // interface consistent with editorBox
    this.get_code = this.getCode;
    this.set_code = this.setCode;
    this.insert_code = this.insertCode;

    // test override points
    this.indicator = false;
    this.handleTextareaChange = this.handleTextareaChange.bind(this);
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
    if (element.complete) {
      this.contentInserted(element);
    } else {
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
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.refs.rce));
    Bridge.detachEditor(this);
    this.props.onRemove && this.props.onRemove(this);
  }

  getTextarea() {
    return document.getElementById(this.props.textareaId);
  }

  textareaValue() {
    return this.getTextarea().value;
  }

  toggle() {
    if (this.isHidden()) {
      this.setCode(this.textareaValue());
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

  onFocus() {
    Bridge.focusEditor(this);
    this.props.onFocus && this.props.onFocus(this);
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

  accessibilizeEditor(_e, editor) {
    let accessibleEditor = new editorAccessibility(editor, document);
    accessibleEditor.addLabels();
    accessibleEditor.accessibilizeMenubar();
    accessibleEditor.removeStatusbarFromTabindex();
  }

  componentWillUnmount() {
    if (!this._destroyCalled) {
      this.destroy();
    }
  }

  wrapOptions(options = {}) {
    const setupCallback = options.setup;
    options.setup = editor => {
      editorWrappers.set(editor, this);
      if (typeof setupCallback === "function") {
        setupCallback(editor);
      }
    };
    return options;
  }

  handleTextareaChange() {
    if (this.isHidden()) {
      this.setCode(this.textareaValue());
    }
  }

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
    return (
      <TinyMCE
        ref="rce"
        id={this.props.textareaId}
        tinymce={this.props.tinymce}
        className={this.props.textareaClassName}
        onPreInit={this.annotateEditor.bind(this)}
        onInit={this.accessibilizeEditor.bind(this)}
        onClick={this.onFocus.bind(this)}
        onKeypress={this.onFocus.bind(this)}
        onActivate={this.onFocus.bind(this)}
        onRemove={this.onRemove.bind(this)}
        content={this.props.defaultContent}
        config={this.wrapOptions(this.props.editorOptions)}
      />
    );
  }
}

RCEWrapper.propTypes = {
  defaultContent: React.PropTypes.string,
  language: React.PropTypes.string,
  tinymce: React.PropTypes.object,
  textareaId: React.PropTypes.string,
  textareaClassName: React.PropTypes.string,
  editorOptions: React.PropTypes.object,
  onFocus: React.PropTypes.func,
  onRemove: React.PropTypes.func,
  handleUnmount: React.PropTypes.func
};
