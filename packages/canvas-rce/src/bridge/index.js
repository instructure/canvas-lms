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

let focusedEditor = null;
let resolveEditorRendered;

const Bridge = {
  activeEditor() {
    return focusedEditor;
  },

  focusEditor(editor) {
    focusedEditor = editor;
  },

  detachEditor(editor) {
    if (editor === focusedEditor) {
      focusedEditor = null;
    }
  },

  getEditor() {
    return focusedEditor;
  },

  renderEditor(editor) {
    resolveEditorRendered();
    if (focusedEditor === null) {
      focusedEditor = editor;
    }
  },

  editorRendered: new Promise(resolve => {
    resolveEditorRendered = resolve;
  }),

  existingContentToLink() {
    if (focusedEditor) {
      return focusedEditor.existingContentToLink();
    }
    return false;
  },

  existingContentToLinkIsImg() {
    if (focusedEditor) {
      return focusedEditor.existingContentToLinkIsImg();
    }
    return false;
  },

  insertLink(link) {
    if (focusedEditor) {
      const { selection } = focusedEditor.props.tinymce.get(
        focusedEditor.props.textareaId
      );
      link.selectionDetails = {
        node: selection.getNode(),
        range: selection.getRng()
      };
      focusedEditor.insertLink(link);
    } else {
      console.warn("clicked sidebar link without a focused editor");
    }
  },

  insertImage(image) {
    if (focusedEditor) {
      focusedEditor.insertImage(image);
    } else {
      console.warn("clicked sidebar image without a focused editor");
    }
  },

  embedImage(image) {
    if (
      Bridge.existingContentToLink() &&
      !Bridge.existingContentToLinkIsImg()
    ) {
      Bridge.insertLink({
        title: image.display_name,
        href: image.href,
        embed: { type: "image" }
      });
    } else {
      Bridge.insertImage(image);
    }
  }
};

export default Bridge;
