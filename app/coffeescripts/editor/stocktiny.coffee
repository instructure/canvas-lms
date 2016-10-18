define [
  'tinymce/tinymce'
  'tinymce/themes/modern/theme'
  'tinymce/plugins/autolink/plugin'
  'tinymce/plugins/media/plugin'
  'tinymce/plugins/paste/plugin'
  'tinymce/plugins/table/plugin'
  'tinymce/plugins/textcolor/plugin'
  'tinymce/plugins/link/plugin'
  'tinymce/plugins/directionality/plugin'
  'tinymce/plugins/lists/plugin'
], (tinymce) ->

  # because in the 'optimized' requireJS build, it gets injected as 'undefined'
  tinymce = tinymce || window.tinymce

  # prevent tiny from loading any CSS assets
  tinymce.DOM.loadCSS = ->

  tinymce
