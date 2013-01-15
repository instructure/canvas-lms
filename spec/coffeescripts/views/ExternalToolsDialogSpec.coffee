define [
  'compiled/views/ExternalToolsDialog'
  'compiled/models/ExternalTool'
], ( ExternalToolsDialog, ExternalTool ) ->

  module "ExternalToolsDialog",
    setup: ->
      @externalTool = new ExternalTool()
      @etDialog = new ExternalToolsDialog model: @externalTool

   test "emits", ->
     expect 0
