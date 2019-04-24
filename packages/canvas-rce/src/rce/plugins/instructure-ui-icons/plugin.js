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

import {
  IconBulletListLine,
  IconTextCenteredLine,
  IconTextStartLine,
  IconTextEndLine,
  IconBoldLine,
  IconImageLine,
  IconIndentLine,
  IconClearTextFormattingLine,
  IconItalicLine,
  IconLinkLine,
  IconNumberedListLine,
  IconOutdentLine,
  IconStrikethroughLine,
  IconTextSubscriptLine,
  IconTextSuperscriptLine,
  IconTableLine,
  IconRemoveLinkLine,
} from '@instructure/ui-icons/es/svg'

tinymce.PluginManager.add('instructure-ui-icons', function(editor) {
  // the keys here are what tinymce calls it. the values are the svgs from instUI

  // there are few things here that are commented out that are things that we
  // might want to have our own icon for but one doesn't exist in @instructure/ui-icons
  const icons = {
    'align-center': IconTextCenteredLine,
    // 'align-justify': 1,
    'align-left': IconTextStartLine,
    // 'align-none': 1,
    'align-right': IconTextEndLine,
    // 'arrow-left': 1,
    // 'arrow-right': 1,
    bold: IconBoldLine,
    image: IconImageLine,
    indent: IconIndentLine,
    italic: IconItalicLine,
    link: IconLinkLine,
    // 'list-bull-circle': 1,
    'list-bull-default': IconBulletListLine,
    // 'list-bull-square': 1,
    'list-num-default': IconNumberedListLine,
    // 'list-num-lower-alpha': 1,
    // 'list-num-lower-greek': 1,
    // 'list-num-lower-roman': 1,
    // 'list-num-upper-alpha': 1,
    // 'list-num-upper-roman': 1,
    'ordered-list': IconNumberedListLine,
    outdent: IconOutdentLine,
    'remove-formatting': IconClearTextFormattingLine,
    'strike-through': IconStrikethroughLine,
    subscript: IconTextSubscriptLine,
    superscript: IconTextSuperscriptLine,
    // 'table-cell-properties': 1,
    // 'table-cell-select-all': 1,
    // 'table-cell-select-inner': 1,
    // 'table-delete-column': 1,
    // 'table-delete-row': 1,
    // 'table-delete-table': 1,
    // 'table-insert-column-after': 1,
    // 'table-insert-column-before': 1,
    // 'table-insert-row-above': 1,
    // 'table-insert-row-after': 1,
    // 'table-left-header': 1,
    // 'table-merge-cells': 1,
    // 'table-row-properties': 1,
    // 'table-split-cells': 1,
    // 'table-top-header': 1,
    table: IconTableLine,

    //if we use the instUI one here we won't get the functionality where it
    // updates the icon fill with the color they select
    // 'text-color': IconTextColorLine,

    unlink: IconRemoveLinkLine,
    'unordered-list': IconBulletListLine
  }
  Object.keys(icons).forEach(key => {
    editor.ui.registry.addIcon(key, icons[key].src)
  })

  // TODO: find a better place to put this
  editor.$(`<style>
    /* this is because instUI icons don't have a "height" attribute like tinymce ones do, so this will make them consistent */
    .tox .tox-icon svg:not([height]) { height: 15px }

    /* this is for instUI icons that that dropdown from a SplitButton like in our advlist plugin */
    .tox .tox-collection__item-icon svg:not([height]) {
      height: 24px;
    }
    .tox .tox-collection--toolbar-lg .tox-collection__item-icon {
      height: 24px;
      width: 24px;
    }
  </style>`).appendTo(editor.targetElm.ownerDocument.body)
})
