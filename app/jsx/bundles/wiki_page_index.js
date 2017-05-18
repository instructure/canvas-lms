/*
 * Copyright (C) 2013 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import I18n from 'i18n!pages'
import WikiPageCollection from 'compiled/collections/WikiPageCollection'
import WikiPageIndexView from 'compiled/views/wiki/WikiPageIndexView'
import 'jquery.cookie'

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
