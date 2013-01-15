define [
  'compiled/views/ExternalToolListItem'
  'compiled/models/ExternalTool'
], ( EXListItem, ExternalTool ) ->

  module "ExternalToolListItem",
    setup: ->
      @exTool = new ExternalTool()
      @exListItem = new EXListItem model: @exTool

  test "emits selected event with external tool model when clicked", ->
    model = null
    stub = ( something ) ->
      model = something
    @exListItem.on 'selected', stub
    @exListItem.$el.trigger 'click'
    deepEqual model, @exTool
