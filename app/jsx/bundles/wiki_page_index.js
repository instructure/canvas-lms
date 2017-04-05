import $ from 'jquery'
import I18n from 'i18n!pages'
import WikiPageCollection from 'compiled/collections/WikiPageCollection'
import WikiPageIndexView from 'compiled/views/wiki/WikiPageIndexView'
import 'vendor/jquery.cookie'

const deleted_page_title = $.cookie('deleted_page_title')
if (deleted_page_title) {
  $.cookie('deleted_page_title', null, {path: '/'})
  $.flashMessage(I18n.t('notices.page_deleted', 'The page "%{title}" has been deleted.', {title: deleted_page_title}))
}

$('body').addClass('index').removeClass('with-right-side')

const view = new WikiPageIndexView({
  collection: new WikiPageCollection(),
  contextAssetString: ENV.context_asset_string,
  default_editing_roles: ENV.DEFAULT_EDITING_ROLES,
  WIKI_RIGHTS: ENV.WIKI_RIGHTS
})

view.collection.setParams({sort: 'title', per_page: 30})
view.collection.fetch()

$('#content').append(view.$el)
view.render()
