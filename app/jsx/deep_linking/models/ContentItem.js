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

export default class ContentItem {
  constructor(json) {
    this.assignProperties(json)
  }

  toHtmlString() {
    // override in sub classes
  }

  assignProperties(json) {
    this.properties.forEach(property => {
      this[property] = json[property]
    })
  }

  linkThumbnail() {
    return this.imageTag(this.thumbnail)
  }

  imageTag(src, width, height) {
    const imgTag = document.createElement('img')
    imgTag.setAttribute('src', src)

    if (this.text) {
      imgTag.setAttribute('alt', this.text)
    }

    if (width) {
      imgTag.setAttribute('width', width)
    }

    if (height) {
      imgTag.setAttribute('height', height)
    }

    return imgTag.outerHTML
  }

  anchorTag(innerHTML) {
    const anchorTag = document.createElement('a')
    anchorTag.setAttribute('href', this.safeUrl())
    anchorTag.setAttribute('title', this.title)
    anchorTag.innerHTML = innerHTML
    return anchorTag.outerHTML
  }

  safeUrl() {
    return this.url.replace(/^(data:text\/html|javascript:)/, '#$1')
  }
}
