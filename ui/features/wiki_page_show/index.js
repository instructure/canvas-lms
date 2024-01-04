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
import '@canvas/jquery/jquery.ajaxJSON'
import ready from '@instructure/ready'
import '@canvas/context-modules'
import WikiPage from '@canvas/wiki/backbone/models/WikiPage'
import WikiPageView from './backbone/views/WikiPageView'
import MarkAsDone from '@canvas/util/jquery/markAsDone'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'
import '@canvas/module-sequence-footer'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'

$('body').addClass('show')

ready(() => {
  const lockManager = new LockManager()
  lockManager.init({itemType: 'wiki_page', page: 'show'})

  $('#content').on('click', '#mark-as-done-checkbox', function () {
    MarkAsDone.toggle(this)
  })

  const wikiPage = new WikiPage(ENV.WIKI_PAGE, {
    revision: ENV.WIKI_PAGE_REVISION,
    contextAssetString: ENV.context_asset_string,
  })

  const wikiPageView = new WikiPageView({
    el: '#wiki_page_show',
    model: wikiPage,
    modules_path: ENV.MODULES_PATH,
    wiki_pages_path: ENV.WIKI_PAGES_PATH,
    wiki_page_edit_path: ENV.WIKI_PAGE_EDIT_PATH,
    wiki_page_history_path: ENV.WIKI_PAGE_HISTORY_PATH,
    WIKI_RIGHTS: ENV.WIKI_RIGHTS,
    PAGE_RIGHTS: ENV.PAGE_RIGHTS,
    course_id: ENV.COURSE_ID,
    course_home: ENV.COURSE_HOME,
    course_title: ENV.COURSE_TITLE,
    display_show_all_pages: ENV.DISPLAY_SHOW_ALL_LINK,
  })

  wikiPageView.render()
})

monitorLtiMessages()
