//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import tinymce from 'tinymce/tinymce'
import 'tinymce/themes/modern/theme'
import 'tinymce/plugins/autolink/plugin'
import 'tinymce/plugins/media/plugin'
import 'tinymce/plugins/paste/plugin'
import 'tinymce/plugins/table/plugin'
import 'tinymce/plugins/textcolor/plugin'
import 'tinymce/plugins/link/plugin'
import 'tinymce/plugins/directionality/plugin'
import 'tinymce/plugins/lists/plugin'

// prevent tiny from loading any CSS assets
tinymce.DOM.loadCSS = function() {}

// CNVS-36555 fix for setBaseAndExtent() bug in tinymce ~4.1.4 - 4.5.3 .
// replace when we upgrade tinymce to 4.5.4+. see CNVS-36555
const _init = tinymce.Editor.prototype.init
tinymce.Editor.prototype.init = function() {
  const ret = _init.apply(this, arguments)
  const editor = this
  const _tmceSel = editor.getWin().Selection.prototype
  _tmceSel.setBaseAndExtent = function(an, ao, focusNode, focusOffset) {
    if (
      !focusNode.hasChildNodes() &&
      focusOffset === 1 &&
      editor.dom.getContentEditableParent(focusNode) !== 'false'
    ) {
      return editor.selection.select(focusNode)
    }
  }
  return ret
}
// end CNVS-36555

export default tinymce
