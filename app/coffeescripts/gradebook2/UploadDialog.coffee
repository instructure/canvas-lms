define [
  'jquery'
  'jst/gradebook_uploads_form'
  'jqueryui/dialog'
], ($, gradebook_uploads_form) ->

  class UploadDialog
    constructor: (@context_url) ->
      @init()

    init: (opts={context_url: @context_url}) =>
      locals =
        download_gradebook_csv_url: "#{opts.context_url}/gradebook.csv"
        action: "#{opts.context_url}/gradebook_uploads"
        authenticityToken: ENV.AUTHENTICITY_TOKEN

      dialog = $(gradebook_uploads_form(locals))
      dialog.dialog
          bgiframe: true
          modal: true
          width: 720
          resizable: false
          close: => dialog.remove()
        .fixDialogButtons()
