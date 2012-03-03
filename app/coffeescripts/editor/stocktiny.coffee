define [
  'compiled/editor/markScriptsLoaded'
  'compiled/fn/punch'
  'order!tricktiny'
  'order!tinymce/jscripts/tiny_mce/tiny_mce_src'
  'order!tinymce/jscripts/tiny_mce/langs/en'
  'order!tinymce/jscripts/tiny_mce/themes/advanced/langs/en'
  'order!tinymce/jscripts/tiny_mce/themes/advanced/editor_template'
  'order!tinymce/jscripts/tiny_mce/plugins/media/editor_plugin_src'
  'order!tinymce/jscripts/tiny_mce/plugins/paste/editor_plugin_src'
  'order!tinymce/jscripts/tiny_mce/plugins/paste/langs/en_dlg'
  'order!tinymce/jscripts/tiny_mce/plugins/table/editor_plugin_src'
  'order!tinymce/jscripts/tiny_mce/plugins/table/langs/en_dlg'
  'order!tinymce/jscripts/tiny_mce/plugins/inlinepopups/editor_plugin_src'
], (markScriptsLoaded, punch) ->

  # prevent tiny from loading any CSS assets
  punch tinymce.DOM, 'loadCSS', ->

  # prevents tinyMCE from trying to load these dynamically
  markScriptsLoaded [
    'themes/advanced/editor_template'
    'themes/advanced/langs/en'
    'plugins/media/editor_plugin'
    'plugins/paste/editor_plugin'
    'plugins/paste/langs/en_dlg'
    'plugins/table/editor_plugin'
    'plugins/table/langs/en_dlg'
    'plugins/inlinepopups/editor_plugin'
  ]

  tinymce

