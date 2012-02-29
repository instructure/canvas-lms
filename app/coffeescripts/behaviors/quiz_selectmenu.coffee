define [
  'jquery'
  'vendor/ui.selectmenu'
], ($) ->
  $ ->
    # css tweaks to ensure that it's sufficiently wide so the text doesn't
    # get clipped unnecessarily when we make it a selectmenu. we do this here
    # rather than in the css so as to avoid a flash of ugly content
    #
    # TODO: support HTML answers in dropdowns. to do this, we'll just need to
    #  1. get rid of the escapeHTML: true (default is false)
    #  2. in the views, double-escape any non-html answers going into dropdown
    #     options (yes, really ... escapeHTML should more accurately be named
    #     dontUnescapeAlreadyEscapedHTML)
    $('.question select').css
      '-webkit-appearance': 'none'
      'font-size': '100%'
      'padding-right': '60px'
    .selectmenu escapeHtml: true
