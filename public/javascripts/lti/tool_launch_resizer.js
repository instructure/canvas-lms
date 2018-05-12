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
  constructor (minToolHeight) {
    this.minToolHeight = minToolHeight || 450;
  }

  tool_content_wrapper (wrapperId) {
    let container = $(`div[data-tool-wrapper-id*='${wrapperId}']`);
    if (container.length <= 0 && $('.tool_content_wrapper').length === 1) {
      container = $('.tool_content_wrapper');
    }
    return container;
  }

  resize_tool_content_wrapper (height, container) {
    let setHeight = height
    if (typeof setHeight !== 'number') { setHeight = this.minToolHeight }
    const toolWrapper = container || this.tool_content_wrapper();
    toolWrapper.height(!height || this.minToolHeight > setHeight ? this.minToolHeight : setHeight);
  }
}
