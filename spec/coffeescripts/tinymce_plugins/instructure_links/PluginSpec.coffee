define ['tinymce_plugins/instructure_links/plugin'], (EditorLinks)->

  module "InstructureLinks Tinymce Plugin",
    setup: ->
    teardown: ->

  test "buttonToImg builds an img tag", ->
    target =
      closest: (str)->
        attr: (str)->
          "some/img/url"
    equal(EditorLinks.buttonToImg(target), "<img src='some/img/url'/>")

  test "buttonToImg is not vulnerable to XSS", ->
    target =
      closest: (str)->
        attr: (str)->
          "<script>alert('attacked');</script>"
    equal(EditorLinks.buttonToImg(target), "<img src='&lt;script&gt;alert('attacked');&lt;/script&gt;'/>")
