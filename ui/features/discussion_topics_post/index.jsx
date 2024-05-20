/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {DiscussionTopicsPost} from './react/index'
import ready from '@instructure/ready'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'

ready(() => {
  ReactDOM.render(
    <DiscussionTopicsPost discussionTopicId={ENV.discussion_topic_id} />,
    $('<div class="discussion-redesign-layout"/>').appendTo('#content')[0]
  )
  // page style modifiers
  document.querySelector('body')?.classList.add('full-width')
  document.querySelector('div.ic-Layout-contentMain')?.classList.remove('ic-Layout-contentMain')
  document
    .querySelector('.ic-app-nav-toggle-and-crumbs.no-print')
    ?.setAttribute('style', 'margin: 0 0 0 24px')
  document.querySelector('#easy_student_view')?.setAttribute('style', 'margin: 0 24px')
})
const urlParams = new URLSearchParams(window.location.search)
if (ENV.SEQUENCE != null && !urlParams.get('embed')) {
  // eslint-disable-next-line promise/catch-or-return
  import('@canvas/module-sequence-footer').then(() => {
    $(() => {
      $('<div id="module_sequence_footer" style="margin: 0 16px" />')
        .appendTo('#content')
        .moduleSequenceFooter({
          assetType: 'Discussion',
          assetID: ENV.SEQUENCE.ASSET_ID,
          courseID: ENV.SEQUENCE.COURSE_ID,
        })
    })
  })
}
