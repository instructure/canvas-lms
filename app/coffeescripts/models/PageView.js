/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import Backbone from 'Backbone'
import TextHelper from '../str/TextHelper'
import 'jquery.instructure_misc_helpers' // $.parseUserAgentString

export default class PageView extends Backbone.Model {
  isLinkable() {
    const method = this.get('http_method')
    if (method == null) return true
    return method === 'get'
  }

  summarizedUserAgent() {
    return this.get('app_name') || $.parseUserAgentString(this.get('user_agent'))
  }

  readableInteractionTime() {
    const seconds = this.get('interaction_seconds')
    if (seconds > 5) {
      return Math.round(seconds)
    } else {
      return '--'
    }
  }

  truncatedURL() {
    return TextHelper.truncateText(this.get('url'), {max: 90})
  }
}

PageView.prototype.computedAttributes = [
  'summarizedUserAgent',
  'readableInteractionTime',
  'truncatedURL',
  'isLinkable'
]
