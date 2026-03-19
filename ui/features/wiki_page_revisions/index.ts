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
import ready from '@instructure/ready'
import WikiPage from '@canvas/wiki/backbone/models/WikiPage'
import WikiPageRevisionsCollection from './backbone/collections/WikiPageRevisionsCollection'
import WikiPageContentView from './backbone/views/WikiPageContentView'
import WikiPageRevisionsView from './backbone/views/WikiPageRevisionsView'

$('body').addClass('show revisions')

ready(() => {
  // @ts-expect-error - ENV properties not in GlobalEnv type
  const wikiPage = new WikiPage(ENV.WIKI_PAGE, {
    // @ts-expect-error - ENV properties not in GlobalEnv type
    revision: ENV.WIKI_PAGE_REVISION,
    contextAssetString: ENV.context_asset_string,
  })
  const revisions = new WikiPageRevisionsCollection([], {parentModel: wikiPage})

  const revisionsView = new WikiPageRevisionsView({
    collection: revisions,
    // @ts-expect-error - ENV properties not in GlobalEnv type
    pages_path: ENV.WIKI_PAGES_PATH,
  })

  const contentView = new WikiPageContentView()
  // @ts-expect-error - Backbone view properties
  contentView.$el.appendTo('#wiki_page_revisions')
  // @ts-expect-error - Backbone view properties
  contentView.on('render', () => revisionsView.reposition())
  // @ts-expect-error - Backbone view properties
  contentView.render()

  // @ts-expect-error - Backbone view properties
  revisionsView.on('selectionChanged', (newSelection: any) => {
    contentView.setModel(newSelection.model)
    if (!newSelection.model.get('title') || newSelection.model.get('title') === '') {
      // @ts-expect-error - Backbone view properties
      return contentView.$el.disableWhileLoading(newSelection.model.fetch())
    }
  })
  // @ts-expect-error - Backbone view properties
  revisionsView.$el.appendTo('#wiki_page_revisions')
  revisionsView.render()

  revisionsView.collection.setParams({per_page: 10})
  revisionsView.collection.fetch()
})
