define [
  'jquery'
  'underscore'
  'compiled/views/DialogFormView'
  'i18n!pages'
  'jst/wiki/WikiPageDeleteDialog'
], ($, _, DialogFormView, I18n, wrapperTemplate) ->

  dialogDefaults =
    title: I18n.t 'delete_title', 'Delete Wiki Page'
    width: 400
    height: 160

  class WikiPageDeleteDialog extends DialogFormView
    wrapperTemplate: wrapperTemplate
    template: -> I18n.t 'delete_confirmation', 'Are you sure you wish to delete this wiki page?'

    @optionProperty 'wiki_pages_url'

    initialize: (options) ->
      modelView = @model?.view
      super _.extend {}, dialogDefaults, options
      @model?.view = modelView

    submit: (event) ->
      event?.preventDefault()

      destroyDfd = @model.destroy(wait: true)

      dfd = $.Deferred()
      page_title = @model.get('title')
      wiki_pages_url = @wiki_pages_url

      destroyDfd.then =>
        if wiki_pages_url
          window.location.href = wiki_pages_url + "?deleted_page_title=#{encodeURIComponent(page_title)}"
        else
          $.flashMessage I18n.t 'notices.page_deleted', 'The page "%{title}" has been deleted.', title: page_title
          dfd.resolve()
          @close()

      destroyDfd.fail =>
        $.flashError I18n.t 'notices.delete_failed', 'The page "%{title}" could not be deleted.', title: page_title
        dfd.reject()

      @$el.disableWhileLoading dfd
