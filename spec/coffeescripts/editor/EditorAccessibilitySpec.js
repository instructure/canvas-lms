#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'jquery'
  'compiled/editor/stocktiny'
  'compiled/editor/editorAccessibility'
], ($, tinymce, EditorAccessibility)->

  fixtures = $("#fixtures")
  textarea = null
  acc = null
  activeEditorNodes = null

  QUnit.module "EditorAccessibility",
    setup: ->
      textarea = $("<textarea id='a42' data-rich_text='true'></textarea>")
      fixtures.append(textarea)
      tinymce.init({selector: "#fixtures textarea#a42"})
      acc = new EditorAccessibility(tinymce.activeEditor)
      activeEditorNodes = tinymce.activeEditor.getContainer().children
    teardown: ->
      textarea.remove()
      fixtures.empty()
      acc = null
      activeEditorNodes = null

  test "initialization", ->
    equal(acc.$el.length, 1)

  test "cacheElements grabs the relevant tinymce iframe", ->
    acc._cacheElements()
    ok(acc.$iframe.length, 1)

  test "accessiblize() gives a helpful title to the iFrame", ->
    acc.accessiblize()
    equal($(acc.$iframe).attr('title'), "Rich Text Area. Press ALT+F8 for help")

  test "accessiblize() removes the statusbar from the tabindex", ->
    acc.accessiblize()
    statusbar = $(activeEditorNodes).find('.mce-statusbar > .mce-container-body')
    equal(statusbar.attr('tabindex'), "-1")

  test "accessibilize() hides the menubar, Alt+F9 shows it", ->
    acc.accessiblize()
    $menu = $(activeEditorNodes).find(".mce-menubar")
    equal($menu.is(":visible"), false)
    event = {
      isDefaultPrevented: (-> false),
      altKey: true,
      ctrlKey: false,
      metaKey: false,
      shiftKey: false,
      keyCode: 120, #<- this is F9
      preventDefault: (->),
      isImmediatePropagationStopped: (-> false)
    }

    tinymce.activeEditor.fire("keydown", event)
    equal($menu.is(":visible"), true)

  test "accessiblize() gives an aria-label to the role=application div", ->
    acc.accessiblize()
    ok $(acc.$el).attr('aria-label'), "aria-label has a value"
