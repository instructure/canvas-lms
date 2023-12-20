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

import BaseLinkContentItem from './BaseLinkContentItem'
import {ResourceLinkContentItemJson} from '../Lti13ContentItemJson'
import {RceLti13ContentItemContext} from '../RceLti13ContentItem'
import {addQueryParamsToUrl} from '../../../../../util/url-util'
import {PARENT_FRAME_CONTEXT_PARAM} from '../../ExternalToolsEnv'

export default class ResourceLinkContentItem extends BaseLinkContentItem<ResourceLinkContentItemJson> {
  static readonly type = 'ltiResourceLink'

  constructor(json: ResourceLinkContentItemJson, context: RceLti13ContentItemContext) {
    super(ResourceLinkContentItem.type, json, context)
  }

  toHtmlString() {
    if (this.iframe != null) {
      // The iframe src must always be the Canvas launch endpoint
      this.iframe.src = this.safeUrl
      return this.iframeTag()
    } else {
      return this.anchorTag(this.linkBody())
    }
  }

  override buildUrl() {
    // iframed launches need canvas wrapped around them for postMessages to work
    const display = this.iframe != null ? 'in_rce' : 'borderless'
    return addQueryParamsToUrl(this.context.ltiEndpoint, {
      display,
      resource_link_lookup_uuid: this.lookup_uuid,
      [PARENT_FRAME_CONTEXT_PARAM]: this.context.containingCanvasLtiToolId,
    })
  }
}
