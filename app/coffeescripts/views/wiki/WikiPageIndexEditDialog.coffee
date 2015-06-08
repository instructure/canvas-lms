define [
  'jquery'
  'underscore'
  'i18n!pages'
  'str/htmlEscape'
  'compiled/views/DialogFormView'
  'jst/wiki/WikiPageIndexEditDialog'
], ($, _, I18n, htmlEscape, DialogFormView, wrapperTemplate) ->

  dialogDefaults =
    fixDialogButtons: false
    title: I18n.t 'edit_dialog_title', 'Edit Wiki Page'
    width: 450
    height: 230
    minWidth: 450
    minHeight: 230


  class WikiPageIndexEditDialog extends DialogFormView
    setViewProperties: false
    className: 'page-edit-dialog'

    returnFocusTo: null

    wrapperTemplate: wrapperTemplate
    template: -> ''

    initialize: (options = {}) ->
      @returnFocusTo = options.returnFocusTo
      super _.extend {}, dialogDefaults, options

    setupDialog: ->
      super

      form = @

      # Add a close event for focus handling
      form.$el.on('dialogclose', (event, ui) =>
        @returnFocusTo?.focus()
      )

      buttons = [
        class: 'btn'
        text: I18n.t 'cancel_button', 'Cancel'
        click: =>
          form.$el.dialog 'close'
          @returnFocusTo?.focus()
      ,
        class: 'btn btn-primary'
        text: I18n.t 'save_button', 'Save'
        'data-text-while-loading': I18n.t 'saving_button', 'Saving...'
        click: =>
          form.submit()
          @returnFocusTo?.focus()
      ]
      @$el.dialog 'option', 'buttons', buttons

    openAgain: ->
      super
      @.$('[name="title"]').focus()
