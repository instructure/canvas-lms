define [
  'tinymce_plugins/instructure_external_tools/initializeExternalTools',
], (initializeExternalTools) ->

  setUp = (maxButtons) ->
    INST = {}
    INST.editorButtons = [
      {id: "button_id"}
    ]
    INST.maxVisibleEditorButtons = maxButtons
    @commandSpy = sinon.spy()
    @buttonSpy = sinon.spy()
    @fakeEditor = {
      addCommand: @commandSpy,
      addButton: @buttonSpy
    }
    @INST = INST

  module "initializeExternalTools: with 2 max maxVisibleEditorButtons",
    setup: ->
      setUp.call(@, 2)
    teardown: ->

  test "adds button directly to toolbar", ->
    initResult = initializeExternalTools(@fakeEditor, "some.fake.url", @INST)
    equal initResult, null
    ok @buttonSpy.calledWith "instructure_external_button_button_id"
    ok @commandSpy.calledWith "instructureExternalButtonbutton_id"

  module "initializeExternalTools: with 0 max maxVisibleEditorButtons",
    setup: ->
      setUp.call(@, 0)
    teardown: ->

  test "adds button to clumped buttons", ->
    initResult = initializeExternalTools(@fakeEditor, "some.fake.url", @INST)
    equal initResult, null
    ok @buttonSpy.calledWith("instructure_external_button_clump")
    ok @commandSpy.notCalled