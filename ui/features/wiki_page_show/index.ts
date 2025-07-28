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

import ready from '@instructure/ready'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/context-modules'
import WikiPage from '@canvas/wiki/backbone/models/WikiPage'
import WikiPageView from './backbone/views/WikiPageView'
import MarkAsDone from '@canvas/util/jquery/markAsDone'
import LockManager from '@canvas/blueprint-courses/react/components/LockManager/index'
import '@canvas/module-sequence-footer'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

interface WikiPageShowEnv {
  MODULES_PATH: string
  WIKI_PAGES_PATH: string
  WIKI_PAGE_EDIT_PATH: string
  WIKI_PAGE_HISTORY_PATH: string
  WIKI_PAGE_REVISION: string
  WIKI_RIGHTS: {[key: string]: boolean}
  PAGE_RIGHTS: {[key: string]: boolean}
  COURSE_HOME: string
  COURSE_TITLE: string
  DISPLAY_SHOW_ALL_LINK: boolean
}
declare const ENV: GlobalEnv & WikiPageShowEnv

document.body.classList.add('show')

ready(() => {
  const lockManager = new LockManager()
  lockManager.init({itemType: 'wiki_page', page: 'show'})

  const content = document.getElementById('content')
  if (content === null) throw new Error('Content element not found')
  content.addEventListener('click', e => {
    const checkbox = (e.target as HTMLElement).closest('#mark-as-done-checkbox')
    if (checkbox) MarkAsDone.toggle(checkbox)
  })

  // @ts-expect-error
  const wikiPage = new WikiPage(ENV.WIKI_PAGE, {
    revision: ENV.WIKI_PAGE_REVISION,
    contextAssetString: ENV.context_asset_string,
  })

  // @ts-expect-error
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
