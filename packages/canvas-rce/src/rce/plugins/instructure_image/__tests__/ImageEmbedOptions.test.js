/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {
  CUSTOM,
  EXTRA_LARGE,
  LARGE,
  MEDIUM,
  MIN_WIDTH,
  MIN_HEIGHT,
  SMALL,
  fromImageEmbed,
  fromVideoEmbed,
  labelForImageSize,
  scaleImageForHeight,
  scaleImageForWidth,
  scaleToSize,
} from '../ImageEmbedOptions'
import RCEGlobals from '../../../RCEGlobals'

Object.defineProperty(HTMLImageElement.prototype, 'naturalHeight', {
  get() {
    return this._naturalHeight
  },
})

Object.defineProperty(HTMLImageElement.prototype, 'naturalWidth', {
  get() {
    return this._naturalWidth
  },
})

describe('RCE > Plugins > Instructure Image > ImageEmbedOptions', () => {
  describe('.fromImageEmbed()', () => {
    let $container
    let $image

    beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      $image = $container.appendChild(document.createElement('img'))
      $image.src = 'https://www.fillmurray.com/640/480'
      $image.alt = 'The ineffable Bill Murray'

      $image._naturalHeight = 480
      $image._naturalWidth = 640
    })

    afterEach(() => {
      $container.remove()
    })

    function getImageOptions() {
      return fromImageEmbed($image)
    }

    describe('.altText', () => {
      it('is the alt text of the image when present', () => {
        expect(getImageOptions().altText).toEqual('The ineffable Bill Murray')
      })

      it('is blank when absent on the image', () => {
        $image.removeAttribute('alt')
        expect(getImageOptions().altText).toEqual('')
      })
    })

    describe('.appliedHeight', () => {
      it('is the numeric height applied to the image', () => {
        $image.setAttribute('height', '220')
        expect(getImageOptions().appliedHeight).toEqual(220)
      })

      it('is null when no height has been applied to the image', () => {
        expect(getImageOptions().appliedHeight).toBeNull()
      })
    })

    describe('.appliedWidth', () => {
      it('is the numeric width applied to the image', () => {
        $image.setAttribute('width', '220')
        expect(getImageOptions().appliedWidth).toEqual(220)
      })

      it('is null when no width has been applied to the image', () => {
        expect(getImageOptions().appliedWidth).toBeNull()
      })
    })

    describe('.imageSize', () => {
      describe('when the image has an applied width and height', () => {
        describe('when the applied width is larger than the applied height', () => {
          beforeEach(() => {
            $image.setAttribute('height', '100')
          })

          it('is "small" when the applied width equals the small image preset width', () => {
            $image.setAttribute('width', '200')
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the applied width equals the medium image preset width', () => {
            $image.setAttribute('width', '320')
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the applied width equals the large image preset width', () => {
            $image.setAttribute('width', '400')
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the applied width equals the extra large image preset width', () => {
            $image.setAttribute('width', '640')
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the applied width is any other numerical value', () => {
            $image.setAttribute('width', '201')
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })

        describe('when the applied height is larger than the applied width', () => {
          beforeEach(() => {
            $image.setAttribute('width', '100')
          })

          it('is "small" when the applied height equals the small image preset height', () => {
            $image.setAttribute('height', '200')
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the applied height equals the medium image preset height', () => {
            $image.setAttribute('height', '320')
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the applied height equals the large image preset height', () => {
            $image.setAttribute('height', '400')
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the applied height equals the extra large image preset height', () => {
            $image.setAttribute('height', '640')
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the applied height is any other numerical value', () => {
            $image.setAttribute('height', '201')
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })
      })

      describe('when the image has only an applied width', () => {
        beforeEach(() => {
          $image.removeAttribute('height')
        })

        describe('when the applied width is larger than the natural height', () => {
          beforeEach(() => {
            $image._naturalHeight = 100
          })

          it('is "small" when the applied width equals the small image preset width', () => {
            $image.setAttribute('width', '200')
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the applied width equals the medium image preset width', () => {
            $image.setAttribute('width', '320')
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the applied width equals the large image preset width', () => {
            $image.setAttribute('width', '400')
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the applied width equals the extra large image preset width', () => {
            $image.setAttribute('width', '640')
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the applied width is any other numerical value', () => {
            $image.setAttribute('width', '201')
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })

        describe('when the natural height is larger than the applied width', () => {
          beforeEach(() => {
            $image.setAttribute('width', '100')
          })

          it('is "small" when the natural height equals the small image preset height', () => {
            $image._naturalHeight = 200
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the natural height equals the medium image preset height', () => {
            $image._naturalHeight = 320
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the natural height equals the large image preset height', () => {
            $image._naturalHeight = 400
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the natural height equals the extra large image preset height', () => {
            $image._naturalHeight = 640
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the natural height is any other numerical value', () => {
            $image._naturalHeight = 201
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })
      })

      describe('when the image has only an applied height', () => {
        beforeEach(() => {
          $image.removeAttribute('width')
        })

        describe('when the applied height is larger than the natural width', () => {
          beforeEach(() => {
            $image._naturalWidth = 100
          })

          it('is "small" when the applied height equals the small image preset height', () => {
            $image.setAttribute('height', '200')
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the applied height equals the medium image preset height', () => {
            $image.setAttribute('height', '320')
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the applied height equals the large image preset height', () => {
            $image.setAttribute('height', '400')
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the applied height equals the extra large image preset height', () => {
            $image.setAttribute('height', '640')
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the applied height is any other numerical value', () => {
            $image.setAttribute('height', '201')
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })

        describe('when the natural width is larger than the applied height', () => {
          beforeEach(() => {
            $image.setAttribute('height', '100')
          })

          it('is "small" when the natural height equals the small image preset height', () => {
            $image._naturalWidth = 200
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the natural height equals the medium image preset height', () => {
            $image._naturalWidth = 320
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the natural height equals the large image preset height', () => {
            $image._naturalWidth = 400
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the natural height equals the extra large image preset height', () => {
            $image._naturalWidth = 640
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the natural height is any other numerical value', () => {
            $image._naturalWidth = 201
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })
      })

      describe('when the image has no applied dimensions', () => {
        beforeEach(() => {
          $image.removeAttribute('height')
          $image.removeAttribute('width')
        })

        describe('when the natural height is larger than the natural width', () => {
          beforeEach(() => {
            $image._naturalWidth = 100
          })

          it('is "small" when the natural height equals the small image preset height', () => {
            $image._naturalHeight = 200
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the natural height equals the medium image preset height', () => {
            $image._naturalHeight = 320
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the natural height equals the large image preset height', () => {
            $image._naturalHeight = 400
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the natural height equals the extra large image preset height', () => {
            $image._naturalHeight = 640
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the natural height is any other numerical value', () => {
            $image._naturalHeight = 201
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })

        describe('when the natural width is larger than the natural height', () => {
          beforeEach(() => {
            $image._naturalHeight = 100
          })

          it('is "small" when the natural height equals the small image preset height', () => {
            $image._naturalWidth = 200
            expect(getImageOptions().imageSize).toEqual(SMALL)
          })

          it('is "medium" when the natural height equals the medium image preset height', () => {
            $image._naturalWidth = 320
            expect(getImageOptions().imageSize).toEqual(MEDIUM)
          })

          it('is "large" when the natural height equals the large image preset height', () => {
            $image._naturalWidth = 400
            expect(getImageOptions().imageSize).toEqual(LARGE)
          })

          it('is "extra large" when the natural height equals the extra large image preset height', () => {
            $image._naturalWidth = 640
            expect(getImageOptions().imageSize).toEqual(EXTRA_LARGE)
          })

          it('is "custom" when the natural height is any other numerical value', () => {
            $image._naturalWidth = 201
            expect(getImageOptions().imageSize).toEqual(CUSTOM)
          })
        })
      })
    })

    describe('.isDecorativeImage', () => {
      describe('when have some attributes on the image element', () => {
        it('is true when the image has no alt text', () => {
          $image.alt = ''
          expect(getImageOptions().isDecorativeImage).toEqual(true)
        })

        it('is false when the image has alt text', () => {
          $image.alt = 'Example image'
          expect(getImageOptions().isDecorativeImage).toEqual(false)
        })
      })

      it('is blank when absent on the image', () => {
        $image.alt = ''
        expect(getImageOptions().isDecorativeImage).toEqual(true)
      })

      describe('when role="presentation"', () => {
        beforeEach(() => {
          $image.setAttribute('role', 'presentation')
        })

        it('is true', () => {
          $image.alt = ''
          expect(getImageOptions().isDecorativeImage).toEqual(true)
        })
      })

      describe('when role != "presentation"', () => {
        beforeEach(() => {
          $image.setAttribute('role', 'menuitem')
        })

        it('is false', () => {
          expect(getImageOptions().isDecorativeImage).toEqual(false)
        })
      })

      describe('when there is no role', () => {
        beforeEach(() => {
          $image.removeAttribute('role')
        })

        it('is false', () => {
          expect(getImageOptions().isDecorativeImage).toEqual(false)
        })
      })
    })

    describe('.appliedPercentage', () => {
      it('is the percentage width when applied to the image', () => {
        $image.setAttribute('width', '50%')
        expect(getImageOptions().appliedPercentage).toEqual(50)
      })

      it('is the percentage height when applied to the image', () => {
        $image.setAttribute('height', '60%')
        expect(getImageOptions().appliedPercentage).toEqual(60)
      })

      it('is the percentage attribute when percentage width and height applied to the image', () => {
        $image.setAttribute('width', '50%')
        $image.setAttribute('height', '60%')
        expect(getImageOptions().appliedPercentage).toEqual(50)
      })

      it('is the percentage attribute when percentage and pixels width/height applied to the image', () => {
        $image.setAttribute('width', '50%')
        $image.setAttribute('height', '30px')
        expect(getImageOptions().appliedPercentage).toEqual(50)
      })

      it('is 100 when no percentage width or height has been applied to the image', () => {
        expect(getImageOptions().appliedPercentage).toEqual(100)
      })
    })

    describe('.usePercentageUnits', () => {
      it('is true when percentage width applied to the image', () => {
        $image.setAttribute('width', '50%')
        expect(getImageOptions().usePercentageUnits).toEqual(true)
      })

      it('is true when percentage height applied to the image', () => {
        $image.setAttribute('height', '60%')
        expect(getImageOptions().usePercentageUnits).toEqual(true)
      })

      it('is true when percentage width and height applied to the image', () => {
        $image.setAttribute('width', '50%')
        $image.setAttribute('height', '60%')
        expect(getImageOptions().usePercentageUnits).toEqual(true)
      })

      it('is true when percentage width and pixels height applied to the image', () => {
        $image.setAttribute('width', '50%')
        $image.setAttribute('height', '30px')
        expect(getImageOptions().usePercentageUnits).toEqual(true)
      })

      it('is false when no percentage width or height has been applied to the image', () => {
        expect(getImageOptions().usePercentageUnits).toEqual(false)
      })
    })

    it('sets .naturalHeight to the natural height of the image', () => {
      expect(getImageOptions().naturalHeight).toEqual(480)
    })

    it('sets .naturalWidth to the natural width of the image', () => {
      expect(getImageOptions().naturalWidth).toEqual(640)
    })

    it('sets .url to the src of the image', () => {
      expect(getImageOptions().url).toEqual('https://www.fillmurray.com/640/480')
    })
  })

  describe('.scaleImageForHeight()', () => {
    it('scales an image to the target height', () => {
      const dimensions = scaleImageForHeight(480, 640, 120)
      expect(dimensions).toEqual({width: 90, height: 120})
    })

    it(`respects the minimum height of ${MIN_HEIGHT}px`, () => {
      const dimensions = scaleImageForHeight(960, 480, 1)
      expect(dimensions).toEqual({width: MIN_HEIGHT * 2, height: MIN_HEIGHT})
    })

    it(`respects the minimum width of ${MIN_WIDTH}px`, () => {
      const dimensions = scaleImageForHeight(480, 960, 1)
      expect(dimensions).toEqual({width: MIN_WIDTH, height: MIN_WIDTH * 2})
    })
  })

  describe('.scaleImageForWidth()', () => {
    it('scales an image to the target width', () => {
      const dimensions = scaleImageForWidth(640, 480, 120)
      expect(dimensions).toEqual({width: 120, height: 90})
    })

    it(`respects the minimum width of ${MIN_WIDTH}px`, () => {
      const dimensions = scaleImageForWidth(480, 960, 1)
      expect(dimensions).toEqual({width: MIN_WIDTH, height: MIN_WIDTH * 2})
    })

    it(`respects the minimum height of ${MIN_HEIGHT}px`, () => {
      const dimensions = scaleImageForWidth(960, 480, 1)
      expect(dimensions).toEqual({width: MIN_HEIGHT * 2, height: MIN_HEIGHT})
    })
  })

  describe('.scaleToSize()', () => {
    it(`scales to fit the '${SMALL}' image size`, () => {
      const dimensions = scaleToSize(SMALL, 640, 480)
      expect(dimensions).toEqual({width: 200, height: 150})
    })

    it(`scales to fit the '${MEDIUM}' image size`, () => {
      const dimensions = scaleToSize(MEDIUM, 480, 640)
      expect(dimensions).toEqual({width: 240, height: 320})
    })

    it(`scales to fit the '${LARGE}' image size`, () => {
      const dimensions = scaleToSize(LARGE, 640, 480)
      expect(dimensions).toEqual({width: 400, height: 300})
    })

    it(`scales to fit the '${EXTRA_LARGE}' image size`, () => {
      const dimensions = scaleToSize(EXTRA_LARGE, 640, 480)
      expect(dimensions).toEqual({width: 640, height: 480})
    })

    it(`returns the given width and height for the '${CUSTOM}' image size`, () => {
      const dimensions = scaleToSize(CUSTOM, 960, 720)
      expect(dimensions).toEqual({width: 960, height: 720})
    })
  })

  describe('.labelForImageSize()', () => {
    it(`returns 'Small' when given '${SMALL}'`, () => {
      expect(labelForImageSize(SMALL)).toEqual('Small')
    })

    it(`returns 'Medium' when given '${MEDIUM}'`, () => {
      expect(labelForImageSize(MEDIUM)).toEqual('Medium')
    })

    it(`returns 'Large' when given '${LARGE}'`, () => {
      expect(labelForImageSize(LARGE)).toEqual('Large')
    })

    it(`returns 'Extra Large' when given '${EXTRA_LARGE}'`, () => {
      expect(labelForImageSize(EXTRA_LARGE)).toEqual('Extra Large')
    })

    it(`returns 'Custom' when given '${CUSTOM}'`, () => {
      expect(labelForImageSize(CUSTOM)).toEqual('Custom')
    })

    it(`returns 'Custom' when given any other value`, () => {
      expect(labelForImageSize('unknown')).toEqual('Custom')
    })
  })

  describe('fromVideoEmbed', () => {
    let $container
    let $video

    beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      const $tinymce_iframe_span = document.createElement('span')
      $tinymce_iframe_span.setAttribute('data-mce-p-title', 'Video player for My Title')
      $tinymce_iframe_span.setAttribute('style', 'display:inline-block;width:320px;height:180px;')
      $container.appendChild($tinymce_iframe_span)

      const $iframe = document.createElement('iframe')
      $tinymce_iframe_span.appendChild($iframe)
      $iframe.contentDocument.body.innerHTML = `
      <div id="player_container">
        <div data-tracks='[{"locale": "en","language":"English"}]'>
          <video/>
        </div>
      </div>
      `

      $video = $tinymce_iframe_span
    })

    afterEach(() => {
      $container.remove()
    })

    function getVideoOptions() {
      return fromVideoEmbed($video)
    }

    it('gets the title', () => {
      expect(getVideoOptions().titleText).toEqual('My Title')
    })

    it('gets the tracks', () => {
      expect(getVideoOptions().tracks).toEqual([{locale: 'en', language: 'English'}])
    })

    it('gets the preset size', () => {
      expect(getVideoOptions().videoSize).toEqual('custom') // cuz it's 0x0
    })

    // that's all we can unit test because we can't fully setup the video,
    // and the element doesn't have a size in jsdom

    describe('attachmentId', () => {
      beforeEach(() => {
        $video.innerHTML =
          '<iframe allow="fullscreen" allowfullscreen data-media-id="17" data-media-type="video" src="/media_attachments_iframe/17?type=video&embedded=true" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>'
        RCEGlobals.getFeatures = jest.fn().mockReturnValue({media_links_use_attachment_id: true})
      })

      afterEach(() => {
        jest.resetAllMocks()
      })

      it('is included', () => {
        expect(getVideoOptions().attachmentId).toEqual('17')
      })

      it('is included with non relative src', () => {
        $video.innerHTML =
          '<iframe allow="fullscreen" allowfullscreen data-media-id="17" data-media-type="video" src="https://canvas.docker/media_attachments_iframe/17?type=video&embedded=true" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>'
        expect(getVideoOptions().attachmentId).toEqual('17')
      })

      it('is not included', () => {
        RCEGlobals.getFeatures = jest.fn().mockReturnValue({media_links_use_attachment_id: false})
        expect(getVideoOptions().attachmentId).toBeUndefined()
      })

      it('is not included due invalid src', () => {
        $video.innerHTML =
          '<iframe allow="fullscreen" allowfullscreen data-media-id="17" data-media-type="video" src="/blahblahblah/17?type=video&embedded=true" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>'
        expect(getVideoOptions().attachmentId).toBeUndefined()
      })

      it('is not included due non-existent src', () => {
        $video.innerHTML =
          '<iframe allow="fullscreen" allowfullscreen data-media-id="17" data-media-type="video" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>'
        expect(getVideoOptions().attachmentId).toBeUndefined()
      })
    })
  })
})
