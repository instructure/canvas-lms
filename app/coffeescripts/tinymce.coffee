##
# Requires all tinymce dependencies and prevents it from loading  assets

define [
  'compiled/editor/markScriptsLoaded'
  'compiled/editor/stocktiny'

  # instructure plugins
  'tinymce/jscripts/tiny_mce/plugins/instructure_contextmenu/editor_plugin'
  'tinymce/jscripts/tiny_mce/plugins/instructure_embed/editor_plugin'
  'tinymce/jscripts/tiny_mce/plugins/instructure_image/editor_plugin'
  'tinymce/jscripts/tiny_mce/plugins/instructure_equation/editor_plugin'
  'tinymce/jscripts/tiny_mce/plugins/instructure_equella/editor_plugin'
  'tinymce/jscripts/tiny_mce/plugins/instructure_external_tools/editor_plugin'
  'tinymce/jscripts/tiny_mce/plugins/instructure_links/editor_plugin'
  'tinymce/jscripts/tiny_mce/plugins/instructure_record/editor_plugin'
], (markScriptsLoaded, tinymce) ->

  # mark everything we just loaded as done
  markScriptsLoaded [
    'plugins/instructure_contextmenu/editor_plugin'
    'plugins/instructure_embed/editor_plugin'
    'plugins/instructure_image/editor_plugin'
    'plugins/instructure_equation/editor_plugin'
    'plugins/instructure_equella/editor_plugin'
    'plugins/instructure_external_tools/editor_plugin'
    'plugins/instructure_links/editor_plugin'
    'plugins/instructure_record/editor_plugin'
  ]

  tinymce

