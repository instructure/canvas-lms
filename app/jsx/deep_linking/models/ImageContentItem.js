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

import ContentItem from './ContentItem'

export default class ImageContentItem extends ContentItem {
  static type = 'image'

  constructor(json) {
    super(json)
    this.type = ImageContentItem.type
  }

  get properties() {
    return Object.freeze(['url', 'title', 'thumbnail', 'text', 'width', 'height'])
  }

  toHtmlString() {
    if (this.thumbnail) {
      return this.anchorTag(this.linkThumbnail())
    }
    return this.imageTag(this.safeUrl(), this.width, this.height)
  }
}
