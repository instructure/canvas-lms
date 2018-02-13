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
      getContent: ->,
      selection: {getContent: -> }
    }
    @INST = INST

  QUnit.module "initializeExternalTools: with 2 max maxVisibleEditorButtons",
    setup: ->
      setUp.call(@, 2)
    teardown: ->
      $(window).off('beforeunload')

  test "adds button directly to toolbar", ->
    initResult = ExternalToolsPlugin.init(@fakeEditor, "some.fake.url", @INST)
    equal initResult, null
    ok @buttonSpy.calledWith "instructure_external_button_button_id"
    ok @commandSpy.calledWith "instructureExternalButtonbutton_id"

  QUnit.module "initializeExternalTools: with 0 max maxVisibleEditorButtons",
    setup: ->
      setUp.call(@, 0)
    teardown: ->

  test "adds button to clumped buttons", ->
    initResult = ExternalToolsPlugin.init(@fakeEditor, "some.fake.url", @INST)
    equal initResult, null
    ok @buttonSpy.calledWith("instructure_external_button_clump")
    ok @commandSpy.notCalled

  QUnit.module "buttonSelected",
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
