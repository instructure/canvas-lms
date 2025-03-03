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
import DiscussionTopicKeyboardShortcutModal from './react/KeyboardShortcuts/DiscussionTopicKeyboardShortcutModal'
import {Portal} from '@instructure/ui-portal'

function DiscussionPageLayout() {
  return (
    <>
      {!window.ENV.disable_keyboard_shortcuts && (
        <Portal open={true} mountNode={document.getElementById('content')}>
          <div id="keyboard-shortcut-modal">
            <DiscussionTopicKeyboardShortcutModal />
          </div>
        </Portal>
      )}
      <Portal open={true} mountNode={document.getElementById('content')}>
        <div id="discussion-redesign-layout" className="discussion-redesign-layout">
          <DiscussionTopicsPost discussionTopicId={ENV.discussion_topic_id} />
        </div>
      </Portal>
    </>
  )
}

const renderFooter = () => {
  import('@canvas/module-sequence-footer').then(() => {
    $(() => {
      $(`<div id="module_sequence_footer" style="position: fixed; bottom: 0px; z-index: 100" />`)
        .appendTo('#content')
        .moduleSequenceFooter({
          assetType: 'Discussion',
          assetID: ENV.SEQUENCE.ASSET_ID,
          courseID: ENV.SEQUENCE.COURSE_ID,
        })
      adjustFooter()
      new ResizeObserver(adjustFooter).observe(document.getElementById('content'))
    })
  })
}

export const adjustFooter = () => {
  const masqueradeBar = document.getElementById('masquerade_bar');
  const container = $('#module_sequence_footer_container')
  const footer = $('#module_sequence_footer')

  if (container.length > 0) {
    const containerRightPosition = container.css('padding-right')
    const containerWidth = $(container).width() + 'px'
    const masqueradeBarHeight = $(masqueradeBar).height() + 10 + 'px'

    footer.css('width', `calc(${containerWidth} - ${containerRightPosition})`) // width with padding
    footer.css('right', `${containerRightPosition}`)
    footer.css('bottom',  masqueradeBarHeight)
  }
}

ready(() => {
  setTimeout(() => {
    ReactDOM.render(<DiscussionPageLayout />, document.getElementById('content'))
  })

  document.querySelector('body')?.classList.add('full-width')
  document.querySelector('div.ic-Layout-contentMain')?.classList.remove('ic-Layout-contentMain')
  document
    .querySelector('.ic-app-nav-toggle-and-crumbs.no-print')
    ?.setAttribute('style', 'margin: 0 0 0 24px')

  const urlParams = new URLSearchParams(window.location.search)
  if (ENV.SEQUENCE != null && !urlParams.get('embed')) {
    renderFooter()
  }
})
