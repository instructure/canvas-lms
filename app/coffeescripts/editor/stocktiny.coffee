#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'tinymce/tinymce'
  'tinymce/themes/modern/theme'
  'tinymce/plugins/autolink/plugin'
  'tinymce/plugins/media/plugin'
  'tinymce/plugins/paste/plugin'
  'tinymce/plugins/table/plugin'
  'tinymce/plugins/textcolor/plugin'
  'tinymce/plugins/link/plugin'
  'tinymce/plugins/directionality/plugin'
  'tinymce/plugins/lists/plugin'
], (tinymce) ->

  # prevent tiny from loading any CSS assets
  tinymce.DOM.loadCSS = ->

  # CNVS-36555 fix for setBaseAndExtent() bug in tinymce ~4.1.4 - 4.5.3 .
  # replace when we upgrade tinymce to 4.5.4+. see CNVS-36555
  _init = tinymce.Editor.prototype.init
  tinymce.Editor.prototype.init = ->
     ret = _init.apply(this,arguments)
     editor = this
     _tmceSel = editor.getWin().Selection.prototype
     _tmceSel.setBaseAndExtent = (an, ao, focusNode, focusOffset) ->
       if !focusNode.hasChildNodes() and focusOffset==1 and editor.dom.getContentEditableParent(focusNode) isnt "false"
         editor.selection.select(focusNode)
     ret
  # end CNVS-36555

  tinymce
