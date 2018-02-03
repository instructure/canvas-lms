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
import WikiPage from 'compiled/models/WikiPage'
import WikiPageEditView from 'compiled/views/wiki/WikiPageEditView'
import LockManager from '../blueprint_courses/apps/LockManager'

const lockManager = new LockManager()
lockManager.init({ itemType: 'wiki_page', page: 'edit' })

$('body').addClass('edit')

const wikiPage = new WikiPage(ENV.WIKI_PAGE, {
  revision: ENV.WIKI_PAGE_REVISION,
  contextAssetString: ENV.context_asset_string,
  parse: true
})

const lockedItems = lockManager.isChildContent() ? lockManager.getItemLocks() : {}

const wikiPageEditView = new WikiPageEditView({
  model: wikiPage,
  wiki_pages_path: ENV.WIKI_PAGES_PATH,
  WIKI_RIGHTS: ENV.WIKI_RIGHTS,
  PAGE_RIGHTS: ENV.PAGE_RIGHTS,
  lockedItems,
})
$('#content').append(wikiPageEditView.$el)

wikiPageEditView.on('cancel', () => {
  const created_at = wikiPage.get('created_at')
  const html_url = wikiPage.get('html_url')
  if (!created_at || !html_url) {
    if (ENV.WIKI_PAGES_PATH) { window.location.href = ENV.WIKI_PAGES_PATH }
  } else {
    window.location.href = html_url
  }
})

wikiPageEditView.render()
