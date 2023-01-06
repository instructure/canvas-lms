/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

export default class ToolLaunchResizer {
  minToolHeight: number

  constructor(minToolHeight?: number) {
    this.minToolHeight = minToolHeight || 450
  }

  sanitizedWrapperId(wrapperId?: string) {
    return wrapperId?.toString()?.replace(/[^a-zA-Z0-9_-]/g, '')
  }

  tool_content_wrapper(wrapperId?: string) {
    let container = $(`div[data-tool-wrapper-id*='${this.sanitizedWrapperId(wrapperId)}']`)
    const tool_content_wrapper = $('.tool_content_wrapper')
    if (container.length <= 0 && tool_content_wrapper.length === 1) {
      container = tool_content_wrapper
    }
    return container
  }

  resize_tool_content_wrapper(
    height: number | string,

    // disabling b/c eslint fails, saying 'MessageEventSource' is not defined, but it's
    // defined in lib.dom.d.ts
    // eslint-disable-next-line no-undef
    container: JQuery<HTMLElement>,
    force_height = false
  ) {
    let setHeight = height
    if (typeof setHeight !== 'number') {
      setHeight = this.minToolHeight
    }
    const toolWrapper = container || this.tool_content_wrapper()
    if (force_height) toolWrapper.height(setHeight)
    else
      toolWrapper.height(!height || this.minToolHeight > setHeight ? this.minToolHeight : setHeight)
  }
}
