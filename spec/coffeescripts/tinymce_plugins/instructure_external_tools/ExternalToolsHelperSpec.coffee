define [
  'underscore'
  'tinymce_plugins/instructure_external_tools/ExternalToolsHelper',
  'jquery'
], (_, ExternalToolsHelper, $)->

  module "ExternalToolsHelper:buttonConfig",
    setup: ->
      @buttonOpts = {
        name: "SomeName",
        id: "_SomeId"
      }
    teardown: ->

  test "makes a config as expected", ->
    config = ExternalToolsHelper.buttonConfig(@buttonOpts)
    equal config.title, "SomeName"
    equal config.cmd, 'instructureExternalButton_SomeId'
    equal config.classes, 'widget btn instructure_external_tool_button'

  test "modified string to avoid mce prefix", ->
    btn = _.extend({}, @buttonOpts, {canvas_icon_class: "foo-class"})
    config = ExternalToolsHelper.buttonConfig(btn)
    equal config.icon, "hack-to-avoid-mce-prefix foo-class"
    equal config.image, null

  test "defaults to image if no icon class", ->
    btn = _.extend({}, @buttonOpts, {icon_url: "example.com"})
    config = ExternalToolsHelper.buttonConfig(btn)
    equal config.icon, null
    equal config.image, "example.com"

  module "ExternalToolsHelper:clumpedButtonMapping",
    setup: ->
      @clumpedButtons = [
        {id: "ID_1", name: "NAME_1", icon_url: "", canvas_icon_class: "foo"},
        {id: "ID_2", name: "NAME_2", icon_url: "", canvas_icon_class: null},
      ]
      @onClickHander = sinon.spy()

    teardown: ->

  test "returns a hash of markup keys and attaches click handler to value", ->
    mapping = ExternalToolsHelper.clumpedButtonMapping(@clumpedButtons, @onClickHander)

    imageKey = _.chain(mapping).keys().select((k) -> k.match(/img/)).value()[0]
    iconKey = _.chain(mapping).keys().select((k) -> !k.match(/img/)).value()[0]

    imageTag = imageKey.split("&nbsp")[0]
    iconTag = iconKey.split("&nbsp")[0]

    equal $(imageTag).data("toolId"), "ID_2"
    equal $(iconTag).data("toolId"), "ID_1"

    ok @onClickHander.notCalled
    mapping[imageKey]()
    ok @onClickHander.called

  test "returns icon markup if canvas_icon_class in button", ->
    mapping = ExternalToolsHelper.clumpedButtonMapping(@clumpedButtons, () ->)
    iconKey = _.chain(mapping).keys().select((k) -> !k.match(/img/)).value()[0]
    iconTag = iconKey.split("&nbsp")[0]
    equal $(iconTag).prop("tagName"), "I"

  test "returns img markup if no canvas_icon_class", ->
    mapping = ExternalToolsHelper.clumpedButtonMapping(@clumpedButtons, () ->)
    imageKey = _.chain(mapping).keys().select((k) -> k.match(/img/)).value()[0]
    imageTag = imageKey.split("&nbsp")[0]
    equal $(imageTag).prop("tagName"), "IMG"

  module "ExternalToolsHelper:attachClumpedDropdown",
    setup: ->
      @theSpy = sinon.spy()
      @fakeTarget = {
        dropdownList: @theSpy
      }
      @fakeButtons = "fb"
      @fakeEditor = {
        "on": () ->
      }
    teardown: ->

  test "calls dropdownList with buttons as options", ->
    fakeButtons = "fb"
    ExternalToolsHelper.attachClumpedDropdown(@fakeTarget, fakeButtons, @fakeEditor)

    ok @theSpy.calledWith(
      {"options": fakeButtons}
    )
