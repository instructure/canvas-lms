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

import ContentUtils from '../ContentUtils'

describe('ContentUtils', () => {
  const htmlNoImages = `
    <div>
      Sample text content
      <p>Some paragraph content</p>
    </div>
  `

  const htmlNoAnchorWithImage = `
    <div>
      Sample text content
      <img src="http://canvas.docker/some/place/1037/preview">
    </div>
  `

  const htmlWithAnchorAndImage = `
    <div>
      Sample text content
      <a href="http://my/source">My awesome anchor</a>
      <img src="http://canvas.docker/some/place/1037/preview">
    </div>
  `

  const htmlOneHyperlinkedImage = `
    <div>
      Sample text content
      <a href="www.instructure.com">Pandamonium>
        <img src="http://canvas.docker/some/place/1037/preview"
          class="my_class"
          alt="alt text"
        >
      </a>
    </div>
  `

  describe('htmlContainsHyperlinkedImage', () => {
    it('returns false when html string does not contain any images', () => {
      const contentUtils = new ContentUtils(htmlNoImages)
      const hasHyperlinkedImage = contentUtils.htmlContainsHyperlinkedImage()
      expect(hasHyperlinkedImage).toBe(false)
    })

    it('returns false when html does contain image, but it is not hyperlinked', () => {
      const contentUtils = new ContentUtils(htmlNoAnchorWithImage)
      const hasHyperlinkedImage = contentUtils.htmlContainsHyperlinkedImage()
      expect(hasHyperlinkedImage).toBe(false)
    })

    it('returns false when html contains anchor and image, but image is not hyperlinked', () => {
      const contentUtils = new ContentUtils(htmlWithAnchorAndImage)
      const hasHyperlinkedImage = contentUtils.htmlContainsHyperlinkedImage()
      expect(hasHyperlinkedImage).toBe(false)
    })

    it('returns true when html contains one hyperlinked image', () => {
      const contentUtils = new ContentUtils(htmlOneHyperlinkedImage)
      const hasHyperlinkedImage = contentUtils.htmlContainsHyperlinkedImage()
      expect(hasHyperlinkedImage).toBe(true)
    })
  })

  describe('removeAnchorFromHyperlinkedImages', () => {
    const extraAnchor = '<a id="keep-me" href="www.something.com">Not hyperlinking an image</a>'
    const htmlExtraAnchorTag = `
      <div>
        ${extraAnchor}
        Sample text content
        <a href="www.instructure.com">Pandamonium>
          <img src="http://canvas.docker/some/place/1037/preview"
            class="my_class"
            alt="alt text"
          >
        </a>
      </div>
    `
    it('removes parent anchor tag from hyperlinked image', () => {
      const contentUtilsBefore = new ContentUtils(htmlOneHyperlinkedImage)
      let updatedHtml = ''
      // Needs to be true for this test
      if (contentUtilsBefore.htmlContainsHyperlinkedImage()) {
        updatedHtml = contentUtilsBefore.removeAnchorFromHyperlinkedImages()
      }
      // Need new instance of ContentUtils to check if hyperlinked images were removed
      // Provide the new instance with the updated html to check
      const contentUtilsAfter = new ContentUtils(updatedHtml)
      const hasHyperlinkedImage = contentUtilsAfter.htmlContainsHyperlinkedImage()
      expect(hasHyperlinkedImage).toBe(false)
    })

    it('does not remove other anchor tags that are not used to hyperlink an image', () => {
      const contentUtils = new ContentUtils(htmlExtraAnchorTag)
      let updatedHtml = ''
      // htmlContainsHyperlinkedImage() needs to be true for this test
      if (contentUtils.htmlContainsHyperlinkedImage()) {
        updatedHtml = contentUtils.removeAnchorFromHyperlinkedImages()
      }
      expect(updatedHtml).toContain(extraAnchor)
    })
  })
})
