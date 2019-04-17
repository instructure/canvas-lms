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

/*eslint no-console: 0*/
export default class Bridge {
  constructor() {
    this.focusedEditor = null
    this.resolveEditorRendered = null

    this.embedImage = this.embedImage.bind(this)

    this._editorRendered = new Promise(resolve => {
      this.resolveEditorRendered = resolve
    })

    this.insertLink = this.insertLink.bind(this)

    this.trayProps = new WeakMap();
  }

  get editorRendered() {
    return this._editorRendered
  }

  get controller() {
    return this._controller
  }

  activeEditor() {
    return this.focusedEditor;
  }

  focusEditor(editor) {
    this.focusedEditor = editor;
  }

  detachEditor(editor) {
    if (editor === this.focusedEditor) {
      this.focusedEditor = null;
    }
  }

  getEditor() {
    return this.focusedEditor;
  }

  renderEditor(editor) {
    this.resolveEditorRendered();
    if (this.focusedEditor === null) {
      this.focusedEditor = editor;
    }
  }

  attachController(controller) {
    this._controller = controller
  }

  detachController() {
    this._controller = null
  }

  showTrayForPlugin(plugin) {
    this._controller && this._controller.showTrayForPlugin(plugin)
  }

  existingContentToLink() {
    if (this.focusedEditor) {
      return this.focusedEditor.existingContentToLink();
    }
    return false;
  }

  existingContentToLinkIsImg() {
    if (this.focusedEditor) {
      return this.focusedEditor.existingContentToLinkIsImg();
    }
    return false;
  }

  insertLink(link) {
    if (this.focusedEditor) {
      const { selection } = this.focusedEditor.props.tinymce.get(
        this.focusedEditor.props.textareaId
      );
      link.selectionDetails = {
        node: selection.getNode(),
        range: selection.getRng()
      };
      this.focusedEditor.insertLink(link);
      if (this.controller) {
        this.controller.hideTray()
      }
    } else {
      console.warn("clicked sidebar link without a focused editor");
    }
  }

  insertImage(image) {
    if (this.focusedEditor) {
      this.focusedEditor.insertImage(image);
      if (this.controller) {
        this.controller.hideTray()
      }
    } else {
      console.warn("clicked sidebar image without a focused editor");
    }
  }

  embedImage(image) {
    if (
      this.existingContentToLink() &&
      !this.existingContentToLinkIsImg()
    ) {
      this.insertLink({
        title: image.display_name,
        href: image.href,
        embed: { type: "image" }
      });
    } else {
      this.insertImage(image);
    }
  }
}
