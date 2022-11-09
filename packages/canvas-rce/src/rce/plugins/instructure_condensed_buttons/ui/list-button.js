/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import Actions from '../core/Actions'
import ListUtils from '../core/ListUtils'
import formatMessage from '../../../../format-message'

const listTypes = {
  'unordered-default': {
    listType: 'UL',
    icon: 'list-bull-default',
    text: formatMessage('default bulleted unordered list'),
  },
  circle: {
    listType: 'UL',
    icon: 'list-bull-circle',
    text: formatMessage('circle unordered list'),
  },
  square: {
    listType: 'UL',
    icon: 'list-bull-square',
    text: formatMessage('square unordered list'),
  },
  'ordered-default': {
    listType: 'OL',
    icon: 'list-num-default',
    text: formatMessage('default numerical ordered list'),
  },
  'upper-alpha': {
    listType: 'OL',
    icon: 'list-num-upper-alpha',
    text: formatMessage('uppercase alphabetic ordered list'),
  },
  'upper-roman': {
    listType: 'OL',
    icon: 'list-num-upper-roman',
    text: formatMessage('uppercase Roman numeral ordered list'),
  },
}

function selectedListType(listTypes, editor) {
  const selected = ListUtils.getSelectedStyleType(editor)
  return (
    selected &&
    listTypes.find(style => {
      if (selected.listType === 'OL' && style === 'ordered-default' && !selected.listStyleType)
        return true
      if (selected.listType === 'UL' && style === 'unordered-default' && !selected.listStyleType)
        return true
      return style === selected.listStyleType
    })
  )
}

const isWithinList = (editor, e) => {
  const tableCellIndex = Array.prototype.findIndex.call(e.parents, ListUtils.isTableCellNode)
  const parents = tableCellIndex !== -1 ? e.parents.slice(0, tableCellIndex) : e.parents
  const lists = tinymce.grep(parents, ListUtils.isListNode(editor))
  return lists.length > 0 && (lists[0].nodeName === 'UL' || lists[0].nodeName === 'OL')
}

const buttonLabel = formatMessage('Ordered and Unordered Lists')
export default function register(editor) {
  editor.ui.registry.addSplitButton('bullist', {
    tooltip: buttonLabel,
    icon: 'unordered-list',
    presets: 'listpreview',
    columns: 3,

    fetch: callback => {
      const items = Object.keys(listTypes).map(listType => {
        const {icon, text} = listTypes[listType]
        return {
          type: 'choiceitem',
          value: listType,
          icon,
          text,
        }
      })
      callback(items)
    },

    onAction: () => {
      const selected = listTypes[selectedListType(Object.keys(listTypes), editor)]
      const cmd =
        selected && selected.listType === 'OL' ? 'InsertOrderedList' : 'InsertUnorderedList'
      editor.execCommand(cmd)
    },

    onItemAction: (splitButtonApi, value) => {
      const listType = listTypes[value]
      const styleDetail =
        value === 'unordered-default' || value === 'ordered-default' ? false : value
      Actions.applyListFormat(editor, listType.listType, styleDetail)
    },

    select: value => !!selectedListType([value], editor),

    onSetup: api => {
      const $svgContainer = editor.$(
        `.tox-split-button[aria-label="${buttonLabel}"] .tox-icon`,
        document
      )
      const allIcons = editor.ui.registry.getAll().icons

      const nodeChangeHandler = e => {
        const isInList = isWithinList(editor, e)
        api.setActive(isInList)

        let svg = allIcons['list-bull-default']
        if (isInList) {
          const selected = selectedListType(Object.keys(listTypes), editor)
          const icon = allIcons[listTypes[selected]?.icon]
          if (icon !== undefined) {
            svg = icon
          }
        }
        $svgContainer.html(svg)
      }

      nodeChangeHandler({parents: editor.dom.getParents(editor.selection.getNode(), 'ol,ul')})
      editor.on('NodeChange', nodeChangeHandler)
      return () => editor.off('NodeChange', nodeChangeHandler)
    },
  })
}
