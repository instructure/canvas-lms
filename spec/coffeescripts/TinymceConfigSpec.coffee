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
  'tinymce.config'
  'compiled/editor/stocktiny'
], ($,EditorConfig, tinymce)->

  INST = null
  largeScreenWidth = 1300
  dom_id = "some_textarea"
  fake_tinymce = { baseURL: "/base/url" }
  toolbar1 = "bold,italic,underline,forecolor,backcolor,removeformat," +
               "alignleft,aligncenter,alignright"
  toolbar2 = "outdent,indent,superscript,subscript,bullist,numlist,table," +
               "media,instructure_links,unlink,instructure_image," +
               "instructure_equation"
  toolbar3 = "ltr,rtl,fontsizeselect,formatselect,check_a11y"

  QUnit.module "EditorConfig",
    setup: ->
      INST = {}
      INST.editorButtons = []
      INST.maxVisibleEditorButtons = 20

    teardown: ->
      INST = {}

  test 'buttons spread across rows for narrow windowing', ->
    width = 100
    config = new EditorConfig(fake_tinymce, INST, width, dom_id)
    toolbar = config.toolbar()
    ok(toolbar[0] is toolbar1)
    ok(toolbar[1] is toolbar2)
    ok(toolbar[2] is toolbar3)

  test 'buttons go on the first row for large windowing', ->
    config = new EditorConfig(fake_tinymce, INST, largeScreenWidth, dom_id)
    toolbar = config.toolbar()
    equal(toolbar[0], "#{toolbar1},#{toolbar2},#{toolbar3}")
    ok(toolbar[1] is "")
    ok(toolbar[2] is "")

  test "adding a few extra buttons", ->
    INST.editorButtons = [{id: 'example', name: 'new_button'}]
    config = new EditorConfig(fake_tinymce, INST, largeScreenWidth, dom_id)
    toolbar = config.toolbar()
    ok(toolbar[0].match(/instructure_external_button_example/))

  test "calculating an external button clump", ->
    INST.editorButtons = [{id: 'example', name: 'new_button'}]
    INST.maxVisibleEditorButtons = 0
    config = new EditorConfig(fake_tinymce, INST, largeScreenWidth, dom_id)
    btns = config.external_buttons()
    equal(btns, ",instructure_external_button_clump")

  test "default config has static attributes", ->
    INST.maxVisibleEditorButtons = 2
    config = new EditorConfig(fake_tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.skin, false)

  test "default config includes toolbar", ->
    INST.maxVisibleEditorButtons = 2
    config = new EditorConfig(fake_tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.toolbar[0], config.toolbar()[0])

  test "it builds a selector from the id", ->
    config = new EditorConfig(fake_tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.selector, "#some_textarea")

  test "browser spellcheck enabled by default", ->
    config = new EditorConfig(fake_tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.browser_spellcheck, true)

  QUnit.module "Tinymce Config Integration",
    setup: ->
      $("body").append("<textarea id=a42></textarea>")

    teardown: ->
      $("textarea#a42").remove()

  asyncTest "configured not to strip spans", ->
    expect(1)
    $textarea = $("textarea#a42")
    config = new EditorConfig(tinymce, INST, 1000, "a42")
    configHash = $.extend(config.defaultConfig(),{
      plugins: "",
      external_plugins: {},
      init_instance_callback: (editor)->
        content = editor.setContent("<span></span>")
        ok(content.match("<span></span>"))
        start()

    })
    tinymce.init(configHash)
