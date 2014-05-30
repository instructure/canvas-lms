define [
  'Backbone'
  'compiled/models/ExternalTool'
], (Backbone, ExternalTool) ->

  class ExternalToolCollection extends Backbone.Collection

    model: ExternalTool
