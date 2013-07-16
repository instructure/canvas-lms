define [
  'jquery'
  'underscore'
  'i18n!pages'
  'str/htmlEscape'
  'compiled/views/DialogFormView'
  'jst/wiki/WikiPageDeleteDialog'
], ($, _, I18n, htmlEscape, DialogFormView, wrapperTemplate) ->

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
          expires = new Date
          expires.setMinutes(expires.getMinutes() + 1)
          path = '/' # should be wiki_pages_url, but IE will only allow *sub*directries to read the cookie, not the directory itself...
          $.cookie 'deleted_page_title', page_title, expires: expires, path: path
          window.location.href = wiki_pages_url
        else
          $.flashMessage I18n.t 'notices.page_deleted', 'The page "%{title}" has been deleted.', title: page_title
          dfd.resolve()
          @close()

      destroyDfd.fail =>
        $.flashError htmlEscape(I18n.t('notices.delete_failed', 'The page "%{title}" could not be deleted.', title: page_title))
        dfd.reject()

      @$el.disableWhileLoading dfd
