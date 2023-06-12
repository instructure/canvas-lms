// @ts-nocheck
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

import formatMessage from '../../../../format-message'
import {Editor} from 'tinymce'
import {typedKeyDict} from '../../../../util/TypedDict'
import {
  listStyleForSelectionOfEditor,
  ListStyleTypeValue,
  RceSupportedListType,
} from '../core/ListUtils'
import {ExtractRequired} from '../../../../util/ExtractRequired'

/**
 * Supported list style types by the RCE
 */
export type RceListTypeInfoKey = ExtractRequired<
  ListStyleTypeValue,
  'disc' | 'circle' | 'square' | 'decimal' | 'upper-alpha' | 'upper-roman'
>

/**
 * RCE-specific information about a list style type
 */
interface ListStyleTypeInfo {
  /**
   * The html element name associated with this list type
   */
  listType: 'OL' | 'UL'

  /**
   * The css `list-style-type` value associated with this list type
   */
  listStyleType: RceListTypeInfoKey

  /**
   * Icon to be displayed in the editor toolbar
   */
  icon: string

  /**
   * Gets the tooltip text for the associated button.
   *
   * Note: Needs to be a function because translation files aren't loaded when top-level code runs.
   */
  getTooltipText: () => string
}

/**
 * List of list styles supported by the RCE. These will ultimately appear in the toolbar as buttons under the main
 * list button.
 */
const listStyleInfos = typedKeyDict<RceListTypeInfoKey, ListStyleTypeInfo, 'listStyleType'>(
  {
    disc: {
      listType: 'UL',
      icon: 'list-bull-default',
      getTooltipText: () => formatMessage('default bulleted unordered list'),
    },
    circle: {
      listType: 'UL',
      icon: 'list-bull-circle',
      getTooltipText: () => formatMessage('circle unordered list'),
    },
    square: {
      listType: 'UL',
      icon: 'list-bull-square',
      getTooltipText: () => formatMessage('square unordered list'),
    },

    decimal: {
      listType: 'OL',
      icon: 'list-num-default',
      getTooltipText: () => formatMessage('default numerical ordered list'),
    },
    'upper-alpha': {
      listType: 'OL',
      icon: 'list-num-upper-alpha',
      getTooltipText: () => formatMessage('uppercase alphabetic ordered list'),
    },
    'upper-roman': {
      listType: 'OL',
      icon: 'list-num-upper-roman',
      getTooltipText: () => formatMessage('uppercase Roman numeral ordered list'),
    },
  },
  'listStyleType'
)

/**
 * Defines the default `list-style-type` infos for the different list element types.
 */
const defaultStyleInfoForListType: Record<RceSupportedListType, ListStyleTypeInfo> = {
  UL: listStyleInfos.byKey.disc,
  OL: listStyleInfos.byKey.decimal,
}

/**
 * Determines the inner-most list type for the selection in the given Editor.
 */
function listStyleInfoForSelectionOfEditor(editor: Editor): ListStyleTypeInfo | null {
  const selectedStyleType = listStyleForSelectionOfEditor(editor)

  if (!selectedStyleType) return null

  // Prefer to use `list-style-type`-based type infos.
  if (selectedStyleType.listStyleType) {
    const fromStyleType = listStyleInfos.byKey[selectedStyleType.listStyleType]

    if (fromStyleType) return fromStyleType
  }

  // Default to style based on the list element type
  return defaultStyleInfoForListType[selectedStyleType.listType]
}

/**
 * Get the button label.
 *
 * Note: Needs to be a function because translation files aren't loaded when top-level code runs.
 */
const getButtonLabel = () => formatMessage('Ordered and Unordered Lists')

export default function register(editor: Editor) {
  editor.ui.registry.addSplitButton('bullist', {
    tooltip: getButtonLabel(),
    icon: 'unordered-list',
    presets: 'listpreview',
    columns: 3,

    fetch: callback =>
      callback(
        listStyleInfos.values.map(listType => ({
          type: 'choiceitem',
          value: listType.listStyleType,
          icon: listType.icon,
          text: listType.getTooltipText(),
        }))
      ),

    onAction: () =>
      editor.execCommand(
        listStyleInfoForSelectionOfEditor(editor)?.listType === 'OL'
          ? 'InsertOrderedList'
          : 'InsertUnorderedList'
      ),

    onItemAction: (splitButtonApi, value) => {
      const desiredListStyleInfo = listStyleInfos.byKey[value] || defaultStyleInfoForListType.UL

      const currentListStyleInfo = listStyleInfoForSelectionOfEditor(editor)

      // When the user clicks the list button that matches the current list style in the selection,
      // we want to interpret that as un-list-ifying the selection

      if (currentListStyleInfo?.listStyleType !== desiredListStyleInfo.listStyleType) {
        editor.execCommand(
          desiredListStyleInfo.listType === 'UL' ? 'InsertUnorderedList' : 'InsertOrderedList',
          false,
          {'list-style-type': desiredListStyleInfo.listStyleType}
        )
      } else {
        editor.execCommand('RemoveList')
      }
    },

    select: (value: string) => listStyleInfoForSelectionOfEditor(editor)?.listStyleType === value,

    onSetup: api => {
      // Handle updating the icon on the toolbar based on
      // the type of list the user's selection is currently within

      const $iconSvgContainer = editor.$(
        `.tox-split-button[aria-label="${getButtonLabel()}"] .tox-icon`,
        document
      )
      const allIcons = editor.ui.registry.getAll().icons

      const nodeChangeHandler = () => {
        const activeListType = listStyleInfoForSelectionOfEditor(editor)
        api.setActive(!!activeListType)

        $iconSvgContainer.html(allIcons[activeListType?.icon || 'list-bull-default'])
      }

      nodeChangeHandler()
      editor.on('NodeChange', nodeChangeHandler)

      return () => editor.off('NodeChange', nodeChangeHandler)
    },
  })
}
