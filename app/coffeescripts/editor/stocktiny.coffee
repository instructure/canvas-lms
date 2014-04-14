define [
  'compiled/editor/markScriptsLoaded'
  'compiled/fn/punch'
  'tinymce/jscripts/tiny_mce/tiny_mce_src'
  'tinymce/jscripts/tiny_mce/langs/en'
  'tinymce/jscripts/tiny_mce/themes/advanced/langs/en'
  'tinymce/jscripts/tiny_mce/themes/advanced/editor_template_src'
  'tinymce/jscripts/tiny_mce/plugins/media/editor_plugin_src'
  'tinymce/jscripts/tiny_mce/plugins/paste/editor_plugin_src'
  'tinymce/jscripts/tiny_mce/plugins/paste/langs/en_dlg'
  'tinymce/jscripts/tiny_mce/plugins/table/editor_plugin_src'
  'tinymce/jscripts/tiny_mce/plugins/table/langs/en_dlg'
  'tinymce/jscripts/tiny_mce/plugins/inlinepopups/editor_plugin_src'
  'tinymce/jscripts/tiny_mce/plugins/autolink/editor_plugin'
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
    'plugins/autolink/editor_plugin'
  ]

  tinymce

