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

import {RceLti13ContentItem} from '../RceLti13ContentItem'
import {BaseLinkContentItemJson} from '../Lti13ContentItemJson'

// Base content item type
export default class BaseLinkContentItem<
  TJson extends BaseLinkContentItemJson
> extends RceLti13ContentItem<TJson> {
  override toHtmlString() {
    if (this.iframe?.src != null) {
      return this.iframeTag()
    } else {
      return this.anchorTag(this.linkBody())
    }
  }

  linkText() {
    const text = this.buildText()?.trim() ?? ''
    const title = this.buildTitle()?.trim() ?? ''
    return text.length > 0 ? text : title.length > 0 ? title : undefined
  }

  linkBody() {
    if (this.thumbnail) {
      return this.linkThumbnail()
    }
    return this.linkText()
  }

  override buildText() {
    return this.context.selection || this.json.text
  }

  override buildUrl() {
    return this.json.url
  }

  override buildTitle() {
    return this.json.title
  }

  get icon() {
    return this.json.icon
  }

  get thumbnail() {
    return this.json.thumbnail
  }

  get iframe() {
    return this.json.iframe
  }

  get custom() {
    return this.json.custom
  }

  get lookup_uuid() {
    return this.json.lookup_uuid
  }
}
