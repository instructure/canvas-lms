import {Editor} from 'tinymce'

/**
 * Copyright (c) Tiny Technologies, Inc. All rights reserved.
 * Licensed under the LGPL or a commercial license.
 * For LGPL see License.txt in the project root for license information.
 * For commercial licenses see https://www.tiny.cloud/
 */

const isChildOfBody = (editor: Editor, node: Node): boolean =>
  !!editor.$.contains(editor.getBody(), node)

export const isTableCellNode = (node: Node) => node && /^(TH|TD)$/.test(node.nodeName)

export const isListNode =
  (editor: Editor) =>
  (node: Node): boolean =>
    node && /^(OL|UL|DL)$/.test(node.nodeName) && isChildOfBody(editor, node)

export function listStyleForSelectionOfEditor(editor: Editor):
  | {
      listType: RceSupportedListType
      listStyleType?: ListStyleTypeValue
    }
  | undefined {
  const listElm = editor.dom.getParent(editor.selection.getNode(), 'ol,ul')

  if (listElm) {
    return {
      // This is not type safe, but the above getParent selector enforces that this will be
      // either 'OL' or 'UL'
      listType: listElm.nodeName as RceSupportedListType,
      listStyleType: editor.dom.getStyle(listElm, 'listStyleType') as ListStyleTypeValue,
    }
  } else {
    return undefined
  }
}

export type RceSupportedListType = 'UL' | 'OL'

/**
 * Valid values of the "list-style-type" property.
 *
 * NOTE: Not all these types are supported by the RCE. For that, see `ListStyleTypeValue`
 *
 * From https://www.w3schools.com/cssref/pr_list-style-type.php
 */
export type ListStyleTypeValue =
  // Default value. The marker is a filled circle
  | 'disc'
  // The marker is traditional Armenian numbering
  | 'armenian'
  // The marker is a circle
  | 'circle'
  // The marker is plain ideographic numbers
  | 'cjk-ideographic'
  // The marker is a number
  | 'decimal'
  // The marker is a number with leading zeros (01, 02, 03, etc.)
  | 'decimal-leading-zero'
  // The marker is traditional Georgian numbering
  | 'georgian'
  // The marker is traditional Hebrew numbering
  | 'hebrew'
  // The marker is traditional Hiragana numbering
  | 'hiragana'
  // The marker is traditional Hiragana iroha numbering
  | 'hiragana-iroha'
  // The marker is traditional Katakana numbering
  | 'katakana'
  // The marker is traditional Katakana iroha numbering
  | 'katakana-iroha'
  // The marker is lower-alpha (a, b, c, d, e, etc.)
  | 'lower-alpha'
  // The marker is lower-greek
  | 'lower-greek'
  // The marker is lower-latin (a, b, c, d, e, etc.)
  | 'lower-latin'
  // The marker is lower-roman (i, ii, iii, iv, v, etc.)
  | 'lower-roman'
  // No marker is shown
  | 'none'
  // The marker is a square
  | 'square'
  // The marker is upper-alpha (A, B, C, D, E, etc.)
  | 'upper-alpha'
  // The marker is upper-greek
  | 'upper-greek'
  // The marker is upper-latin (A, B, C, D, E, etc.)
  | 'upper-latin'
  // The marker is upper-roman (I, II, III, IV, V, etc.)
  | 'upper-roman'
  // Sets this property to its default value. Read about initial
  | 'initial'
  // Inherits this property from its parent element. Read about inherit
  | 'inherit'
