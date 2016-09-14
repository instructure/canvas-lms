define [
  'tinymce_plugins/instructure_external_tools/initializeExternalTools',
  'jquery',
  'jqueryui/dialog',
], (ExternalToolsPlugin, $) ->

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
      addButton: @buttonSpy,
      selection: {getContent: -> }
    }
    @INST = INST

  module "initializeExternalTools: with 2 max maxVisibleEditorButtons",
    setup: ->
      setUp.call(@, 2)
    teardown: ->
      $(window).off('beforeunload')

  test "adds button directly to toolbar", ->
    initResult = ExternalToolsPlugin.init(@fakeEditor, "some.fake.url", @INST)
    equal initResult, null
    ok @buttonSpy.calledWith "instructure_external_button_button_id"
    ok @commandSpy.calledWith "instructureExternalButtonbutton_id"

  module "initializeExternalTools: with 0 max maxVisibleEditorButtons",
    setup: ->
      setUp.call(@, 0)
    teardown: ->

  test "adds button to clumped buttons", ->
    initResult = ExternalToolsPlugin.init(@fakeEditor, "some.fake.url", @INST)
    equal initResult, null
    ok @buttonSpy.calledWith("instructure_external_button_clump")
    ok @commandSpy.notCalled

  module "buttonSelected",
    setup: ->
      fixtures = document.getElementById('fixtures')
      fixtures.innerHTML = '<a href="http://example.com" id="context_external_tool_resource_selection_url"></a>'
      setUp.call(@, 0)
      @dialogCancelHandler = ExternalToolsPlugin.dialogCancelHandler
    teardown: ->
      $(window).off('beforeunload')
      fixtures.innerHTML = ""
      ExternalToolsPlugin.dialogCancelHandler = @dialogCancelHandler


  test "it attaches the confirm unload handler", ()->
    ExternalToolsPlugin.dialogCancelHandler = sinon.spy()
    $dialog = ExternalToolsPlugin.buttonSelected(@buttonSpy, @fakeEditor)
    $dialog.dialog('close')
    ok ExternalToolsPlugin.dialogCancelHandler.called

  test "it removes the confirm unload handler on externalContentReady event", ()->
    ExternalToolsPlugin.dialogCancelHandler = sinon.spy()
    $dialog = ExternalToolsPlugin.buttonSelected(@buttonSpy, @fakeEditor)
    $(window).trigger("externalContentReady", { contentItems: [{
      "@type": 'LtiLinkItem',
      url: 'http://canvas.instructure.com/test',
      placementAdvice: {
        presentationDocumentTarget: ""
      }
    }] } )
    ok ExternalToolsPlugin.dialogCancelHandler.notCalled

  test "it removes the externalContentReady handler on close", ()->
    externalContentReadySpy = sinon.spy()
    ExternalToolsPlugin.dialogCancelHandler = ()->
    $dialog = ExternalToolsPlugin.buttonSelected(@buttonSpy, @fakeEditor)
    $(window).bind("externalContentReady", externalContentReadySpy)
    $dialog.dialog('close')
    $(window).trigger("externalContentReady", { contentItems: [{
      "@type": 'LtiLinkItem',
      url: 'http://canvas.instructure.com/test',
      placementAdvice: {
        presentationDocumentTarget: ""
      }
    }] } )
    ok externalContentReadySpy.notCalled