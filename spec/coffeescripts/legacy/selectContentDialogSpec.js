#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'select_content_dialog'
], (SelectContentDialog) ->
  QUnit.module "SelectContentDialog: Dialog options",
    setup: ->
      @spy($.fn, 'dialog')
      $("#fixtures").html("<div id='select_context_content_dialog'></div>")

    teardown: ->
      $(".ui-dialog").remove()
      $("#fixtures").html("")

  test "opens a dialog with the width option", ->
    width = 500

    INST.selectContentDialog({width: width})
    equal $.fn.dialog.getCall(0).args[0].width, width

  test "opens a dialog with the height option", ->
    height = 100

    INST.selectContentDialog({height: height})
    equal $.fn.dialog.getCall(0).args[0].height, height

  test "opens a dialog with the dialog_title option", ->
    dialogTitle = "To be, or not to be?"

    INST.selectContentDialog({dialog_title: dialogTitle})
    equal $.fn.dialog.getCall(0).args[0].title, dialogTitle
