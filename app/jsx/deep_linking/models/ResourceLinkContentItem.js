/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import LinkContentItem from './LinkContentItem'

export default class ResourceLinkContentItem extends LinkContentItem {
  constructor(json, ltiEndpoint, selection) {
    super(json, ltiEndpoint, selection)
    this.url = `${ltiEndpoint}?${this.ltiEndpointParams(json.url, json.lookup_id)}`
  }

  ltiEndpointParams(url, lookupId) {
    let endpointParams = 'display=borderless'

    if (lookupId !== null && lookupId !== undefined) {
      endpointParams += `&resource_link_lookup_id=${lookupId}`
    }

    return `${endpointParams}&url=${encodeURIComponent(url)}`
  }

  toHtmlString() {
    if (this.iframe) {
      // The iframe src must always be the Canvas launch endpoint
      this.iframe.src = this.safeUrl()
      return this.iframeTag()
    }

    return this.anchorTag(this.linkBody())
  }
}
