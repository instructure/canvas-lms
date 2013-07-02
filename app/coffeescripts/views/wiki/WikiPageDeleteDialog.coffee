define [
  'underscore'
  'compiled/views/DialogFormView'
  'i18n!pages'
  'jst/wiki/WikiPageDeleteDialog'
], (_, DialogFormView, I18n, wrapperTemplate) ->

  dialogDefaults =
    title: I18n.t 'delete_title', 'Delete Wiki Page'
    width: 400
    height: 160

  class WikiPageDeleteDialog extends DialogFormView
    wrapperTemplate: wrapperTemplate
    template: -> I18n.t 'delete_confirmation', 'Are you sure you wish to delete this wiki page?'

    @optionProperty 'wiki_pages_url'

    initialize: (options) ->
      super _.extend {}, dialogDefaults, options

    submit: (event) ->
      event?.preventDefault()

      page_title = @model.get('title')
      wiki_pages_url = @wiki_pages_url

      dfd = $.Deferred()
      destroyDfd = @model.destroy()
      destroyDfd.then -> window.location = wiki_pages_url + "?deleted_page_title=#{encodeURIComponent(page_title)}"
      destroyDfd.fail -> dfd.reject()

      @$el.disableWhileLoading dfd
