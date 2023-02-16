// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

class ContentUtils {
  private readonly html: Document

  constructor(htmlAsStr: string) {
    const parser = new DOMParser()
    this.html = parser.parseFromString(htmlAsStr, 'text/html')
  }

  htmlContainsHyperlinkedImage(): boolean {
    const hyperlinkedImageList = this.findHyperlinkedImages()

    return hyperlinkedImageList.length > 0
  }

  removeAnchorFromHyperlinkedImages(): string {
    const hyperlinkedImageList = this.findHyperlinkedImages()

    hyperlinkedImageList.forEach(imageElement => {
      const anchorElement = imageElement.parentNode
      const anchorParent = anchorElement?.parentNode
      if (anchorParent) {
        anchorParent.replaceChild(imageElement, anchorElement)
      }
    })
    return this.html.getElementsByTagName('body')[0].innerHTML
  }

  private findHyperlinkedImages(): NodeList {
    return this.html.querySelectorAll('a > img')
  }
}

export default ContentUtils
