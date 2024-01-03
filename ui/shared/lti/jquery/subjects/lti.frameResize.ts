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

import ToolLaunchResizer from '../tool_launch_resizer'
import {findDomForWindow, findDomForWindowInRCEIframe} from '../util'
import type {LtiMessageHandler} from '../lti_message_handler'

const frameResize: LtiMessageHandler<{height: number | string; token: string}> = ({
  message,
  event,
}) => {
  const toolResizer = new ToolLaunchResizer()
  let height: number | string = message.height as number | string
  if (Number(height) <= 0) height = 1

  const container = toolResizer
    .tool_content_wrapper(message.token || event.origin)
    .data('height_overridden', true)
  // If content.length is 0 then jquery didn't the tool wrapper.
  if (container.length > 0) {
    toolResizer.resize_tool_content_wrapper(height, container)
  } else {
    // Attempt to find an embedded iframe that matches the event source.
    const iframe = findDomForWindow(event.source) || findDomForWindowInRCEIframe(event.source)
    if (iframe) {
      const strHeight = typeof height === 'number' ? `${height}px` : height
      iframe.height = strHeight
      iframe.style.height = strHeight
    }
  }
  return false
}

export default frameResize
