define [
  'compiled/editor/markScriptsLoaded'
  'compiled/fn/punch'
  'bower/tinymce/tinymce'
  'bower/tinymce/themes/modern/theme'
  'bower/tinymce/plugins/autolink/plugin'
  'bower/tinymce/plugins/media/plugin'
  'bower/tinymce/plugins/paste/plugin'
  'bower/tinymce/plugins/table/plugin'
  'bower/tinymce/plugins/textcolor/plugin'
  'bower/tinymce/plugins/link/plugin'
], (markScriptsLoaded, punch) ->

  # prevent tiny from loading any CSS assets
  punch tinymce.DOM, 'loadCSS', ->

  # prevents tinyMCE from trying to load these dynamically
  markScriptsLoaded [
    'themes/modern/theme',
    "plugins/autolink/plugin"
    "plugins/media/plugin"
    "plugins/paste/plugin"
    "plugins/table/plugin"
    "plugins/textcolor/plugin"
    "plugins/link/plugin"
  ]

  tinymce
