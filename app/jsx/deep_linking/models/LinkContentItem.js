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

// Base content item type
export default class LinkContentItem {
  static type = 'link'

  constructor(json) {
    this.type = LinkContentItem.type
    this.assignProperties(json)
  }

  get properties() {
    return Object.freeze(['url', 'title', 'text', 'icon', 'thumbnail'])
  }

  toHtmlString() {
    const anchorTag = document.createElement('a')
    anchorTag.setAttribute('href', this.linkUrl())
    anchorTag.setAttribute('title', this.title)
    anchorTag.innerHTML = this.linkBody()
    return anchorTag.outerHTML
  }

  linkText() {
    return (this.text && this.text.trim()) || (this.title && this.title.trim())
  }

  linkBody() {
    if (this.thumbnail) {
      return this.linkThumbnail()
    }
    return this.linkText()
  }

  linkUrl() {
    return this.url.replace(/^(data:text\/html|javascript:)/, "#$1")
  }

  linkThumbnail() {
    const imgTag = document.createElement('img')
    imgTag.setAttribute('src', this.thumbnail)
    imgTag.setAttribute('title', this.title)
    return imgTag.outerHTML
  }

  assignProperties(json) {
    this.properties.forEach(property => {
      this[property] = json[property]
    })
  }
}
