require [
  'i18n!pages'
  'str/htmlEscape'
  'compiled/collections/WikiPageCollection'
  'compiled/views/wiki/WikiPageIndexView'
], (I18n, htmlEscape, WikiPageCollection, WikiPageIndexView) ->

  deleted_page_title = $.cookie('deleted_page_title')
  if deleted_page_title
    $.cookie('deleted_page_title', null, path: '/')
    $.flashMessage htmlEscape(I18n.t('notices.page_deleted', 'The page "%{title}" has been deleted.', title: deleted_page_title))

  $('body').addClass('pages index')

  view = new WikiPageIndexView
    collection: new WikiPageCollection
    contextAssetString: ENV.context_asset_string
    default_editing_roles: ENV.DEFAULT_EDITING_ROLES
    WIKI_RIGHTS: ENV.WIKI_RIGHTS

  view.collection.fetch({data: {sort:'title',per_page:30}}).then ->
    view.fetched = true
    # Re-render after fetching is complete, but only if there are no pages in the collection
    view.render() if view.collection.models.length == 0
  $('#content').append(view.$el)

  view.render()
