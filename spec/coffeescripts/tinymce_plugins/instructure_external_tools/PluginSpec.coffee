define [
  'tinymce/tinymce',
  'tinymce_plugins/instructure_external_tools/plugin'
], (tinymce)->

  module "ExternalTools Plugin",
    setup: ->
    teardown: ->
      $(".ui-dialog").remove()

  test "the InstructureExternalTools plugin is registered to tinymce", ->
     ok tinymce.PluginManager.get('instructure_external_tools')
