define [
  'compiled/models/ExternalTool'
], (ExternalTool) ->

  module "ExternalTool",
    setup: ->
      @prevAssetString = ENV.context_asset_string
      ENV.context_asset_string = "course_3"
      @tool = new ExternalTool()

    teardown: ->
      ENV.context_asset_string = @prevAssetString

  test "urlRoot", ->
    equal @tool.urlRoot(), '/api/v1/courses/3/create_tool_with_verification'

