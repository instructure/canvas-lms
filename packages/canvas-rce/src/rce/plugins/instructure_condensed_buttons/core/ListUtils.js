/**
 * Copyright (c) Tiny Technologies, Inc. All rights reserved.
 * Licensed under the LGPL or a commercial license.
 * For LGPL see License.txt in the project root for license information.
 * For commercial licenses see https://www.tiny.cloud/
 */

const isChildOfBody = (editor, elm) => editor.$.contains(editor.getBody(), elm)

const isTableCellNode = node => node && /^(TH|TD)$/.test(node.nodeName)

const isListNode = editor => node =>
  node && /^(OL|UL|DL)$/.test(node.nodeName) && isChildOfBody(editor, node)

const getSelectedStyleType = editor => {
  const listElm = editor.dom.getParent(editor.selection.getNode(), 'ol,ul')
  if (listElm) {
    return {
      listType: listElm.nodeName,
      listStyleType: editor.dom.getStyle(listElm, 'listStyleType'),
    }
  }
}

export default {
  isTableCellNode,
  isListNode,
  getSelectedStyleType,
}
