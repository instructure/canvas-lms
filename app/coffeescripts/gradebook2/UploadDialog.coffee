define [
  'jquery'
  'jst/gradebook_uploads_form'
  'compiled/behaviors/authenticity_token'
  'jqueryui/dialog'
], ($, gradebook_uploads_form, authenticity_token) ->

  class UploadDialog
    constructor: (@context_url) ->
      @init()

    init: (opts={context_url: @context_url}) =>
      locals =
        download_gradebook_csv_url: "#{opts.context_url}/gradebook.csv"
        action: "#{opts.context_url}/gradebook_uploads"
        authenticityToken: authenticity_token()

      dialog = $(gradebook_uploads_form(locals))
      dialog.dialog
          bgiframe: true
          modal: true
          width: 720
          resizable: false
          close: => dialog.remove()
        .fixDialogButtons()
