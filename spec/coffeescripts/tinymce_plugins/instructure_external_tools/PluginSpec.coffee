define [
  'bower/tinymce/tinymce',
  'tinymce_plugins/instructure_external_tools/plugin'
], (tinymce, ExternalTools)->

  module "ExternalTools Plugin",
    setup: ->
    teardown: ->

  test "buttonConfig populates a config hash with button properties", ->
    button = {
      name: "SomeName"
      id: 42
      icon_url: "/some/image.gif"
    }
    conf = ExternalTools.buttonConfig(button)
    equal(conf.title, button.name)
    equal(conf.cmd, "instructureExternalButton42")
    equal(conf.image, button.icon_url)
    ok(conf.classes.match(/instructure_external_tool_button/))

  test "buttonConfig still has default class definitions", ->
    conf = ExternalTools.buttonConfig({})
    ok(conf.classes.match(/widget/))
    ok(conf.classes.match(/btn/))

  test "clumpedButtonMapping returns a hash of img tags to callbacks", ->
    clump = [{icon_url: 'some/url', name: "somebutton"}]
    items = ExternalTools.clumpedButtonMapping(clump, (->))
    equal(Object.keys(items).length, 1)

  test "clumpedButtonMapping uses a callback for onclick handlers", ->
    clump = [{icon_url: 'some/url', name: "somebutton"}]
    calls = 0
    callback = (()-> calls = calls + 1)
    items = ExternalTools.clumpedButtonMapping(clump, callback)
    items["<img src='some/url'/>&nbsp;somebutton"]()
    equal(calls, 1)

  test "clumpedButtonMapping escapes extremely unlikely XSS attacks", ->
    clump = [{icon_url: 'some/url', name: "<script>alert('attacked')</script>Name"}]
    items = ExternalTools.clumpedButtonMapping(clump, (->))
    escapedKey = "<img src='some/url'/>&nbsp;&lt;script&gt;alert('attacked')&lt;/script&gt;Name"
    equal(Object.keys(items)[0], escapedKey)

  test "attachClumpedDropdown sets up dropdown closure when clicked out of", ->
    target = {
      lastArg: null,
      dropdownList: ((arg)-> @lastArg = arg)
    }
    editor = new tinymce.util.EventDispatcher()
    ExternalTools.attachClumpedDropdown(target, {}, editor)
    editor.fire('click')
    equal(target.lastArg, "hide")
