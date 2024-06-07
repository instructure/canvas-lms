/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

const selector = '.lti-thumbnail-launch'

function handleLaunch(event) {
  event.preventDefault()
  ltiThumbnailLauncher.launch($(event.target).closest(selector))
}

class LtiThumbnailLauncher {
  constructor() {
    $(document.body).on('click', selector, handleLaunch)
  }

  launch(element) {
    const placement = JSON.parse(element.attr('target'))
    const iframe = $('<iframe/>', {
      src: element.attr('href'),
      allowfullscreen: '',
      width: placement.displayWidth || 500,
      height: placement.displayHeight || 500,
    })
    element.replaceWith(iframe)
  }
}

// There can be only one LtiThumbnailLauncher
const ltiThumbnailLauncher = new LtiThumbnailLauncher(selector)
export default ltiThumbnailLauncher
