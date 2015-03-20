define ['tinymce.config'], (EditorConfig)->

  INST = null
  largeScreenWidth = 1300
  dom_id = "some_textarea"
  tinymce = { baseURL: "/base/url" }

  module "EditorConfig",

    setup: ->
      INST = {}
      INST.editorButtons = []
      INST.maxVisibleEditorButtons = 20

    teardown: ->
      INST = {}

  test 'buttons spread across rows for narrow windowing', ->
    width = 100
    config = new EditorConfig(tinymce, INST, width, dom_id)
    toolbar = config.toolbar()
    ok(toolbar[0] is "bold,italic,underline,forecolor,backcolor,removeformat,alignleft,aligncenter,alignright")
    ok(toolbar[1] is "outdent,indent,superscript,subscript,bullist,numlist,table,instructure_links,unlink,instructure_image,instructure_equation")
    ok(toolbar[2] is "fontsizeselect,formatselect")

  test 'buttons go on the first row for large windowing', ->
    config = new EditorConfig(tinymce, INST, largeScreenWidth, dom_id)
    toolbar = config.toolbar()
    equal(toolbar[0], "bold,italic,underline,forecolor,backcolor,removeformat,alignleft,aligncenter,alignright,outdent,indent,superscript,subscript,bullist,numlist,table,instructure_links,unlink,instructure_image,instructure_equation,fontsizeselect,formatselect")
    ok(toolbar[1] is "")
    ok(toolbar[2] is "")

  test "adding a few extra buttons", ->
    INST.editorButtons = [{id: 'example', name: 'new_button'}]
    config = new EditorConfig(tinymce, INST, largeScreenWidth, dom_id)
    toolbar = config.toolbar()
    ok(toolbar[0].match(/instructure_external_button_example/))

  test "calculating an external button clump", ->
    INST.editorButtons = [{id: 'example', name: 'new_button'}]
    INST.maxVisibleEditorButtons = 0
    config = new EditorConfig(tinymce, INST, largeScreenWidth, dom_id)
    btns = config.external_buttons()
    equal(btns, ",instructure_external_button_clump")

  test "default config has static attributes", ->
    INST.maxVisibleEditorButtons = 2
    config = new EditorConfig(tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.skin, 'light')

  test "default config includes toolbar", ->
    INST.maxVisibleEditorButtons = 2
    config = new EditorConfig(tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.toolbar[0], config.toolbar()[0])

  test "it builds a selector from the id", ->
    config = new EditorConfig(tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.selector, "#some_textarea")

  test "it loads up the right skin_url from an absolute path", ->
    config = new EditorConfig(tinymce, INST, largeScreenWidth, dom_id)
    schema = config.defaultConfig()
    equal(schema.skin_url, "/vendor/tinymce_themes/light")
