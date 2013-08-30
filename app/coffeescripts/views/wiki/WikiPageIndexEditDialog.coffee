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
    width: 400
    height: 190

  class WikiPageIndexEditDialog extends DialogFormView
    setViewProperties: false
    className: 'page-edit-dialog'

    wrapperTemplate: wrapperTemplate
    template: -> ''

    initialize: (options) ->
      super _.extend {}, dialogDefaults, options

    setupDialog: ->
      super

      form = @
      buttons = [
        class: 'btn'
        text: I18n.t 'cancel_button', 'Cancel'
        click: -> form.$el.dialog 'close'
      ,
        class: 'btn btn-primary'
        text: I18n.t 'save_button', 'Save'
        'data-text-while-loading': I18n.t 'saving_button', 'Saving...'
        click: -> form.submit()
      ]
      @$el.dialog 'option', 'buttons', buttons

    openAgain: ->
      super
      @.$('[name="wiki_page[title]"]').focus()
