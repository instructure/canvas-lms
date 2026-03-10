/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {forwardedMsgSource} from '../forwarded_msg_source'
import type {LtiMessageHandler} from '../lti_message_handler'

const findIframeBySource = (e: MessageEvent<unknown>) => {
  const source = forwardedMsgSource(e) ?? e.source
  return Array.from(document.querySelectorAll('iframe')).find(f => f.contentWindow === source)
}

const scrollToTop: LtiMessageHandler = params => {
  // When top_navigation_placement FF is on, the page is wrapped in an
  // InstUI DrawerLayout, so html/body can no longer scroll. The actual
  // scroll container becomes #drawer-layout-content in that case.
  const drawerContent = $('#drawer-layout-content')
  const isTopNavEnabled = ENV.FEATURES?.top_navigation_placement && drawerContent.length
  const targetToScroll = isTopNavEnabled ? drawerContent : $('html, body')

  let toolWrapper = $('.tool_content_wrapper')
  if (!toolWrapper.length) {
    // Fall back to finding the iframe by event source,
    // e.g. for RCE content embedded tool iframes, there is no .tool_content_wrapper
    toolWrapper = $(findIframeBySource(params.event) ?? [])
  }
  const offset = toolWrapper.offset()?.top
  if (offset !== undefined) {
    // For a sub-container (drawer), offset().top is viewport-relative (since window.scrollY=0),
    // so we must add the container's current scrollTop to get the correct absolute position within it.
    const scrollTop = offset + (isTopNavEnabled ? (drawerContent.scrollTop() ?? 0) : 0)
    targetToScroll.animate({scrollTop}, 'fast')
  }

  return false
}

export default scrollToTop
