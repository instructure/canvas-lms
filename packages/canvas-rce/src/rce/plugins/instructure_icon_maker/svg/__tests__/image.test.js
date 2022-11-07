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

import {transformForShape, buildImage} from '../image'
import {Shape} from '../shape'
import {Size, DEFAULT_SETTINGS} from '../constants'

describe('transformShape()', () => {
  let shape, size

  const subject = () => transformForShape(shape, size)

  describe('when the shape is a pentagon', () => {
    beforeEach(() => (shape = Shape.Pentagon))

    function sharedExamplesForPentagon() {
      it('uses "55%" for the Y position', () => {
        expect(subject().y).toEqual('55%')
      })
    }

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 40,
          height: 40,
          translateX: -20,
          translateY: -20,
        })
      })

      sharedExamplesForPentagon()
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 80,
          height: 80,
          translateX: -40,
          translateY: -40,
        })
      })

      sharedExamplesForPentagon()
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 110,
          height: 110,
          translateX: -55,
          translateY: -55,
        })
      })

      sharedExamplesForPentagon()
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 140,
          height: 140,
          translateX: -70,
          translateY: -70,
        })
      })

      sharedExamplesForPentagon()
    })
  })

  describe('when the shape is a triangle', () => {
    beforeEach(() => (shape = Shape.Triangle))

    function sharedExamplesForTriangles() {
      it('uses "65%" for the Y position', () => {
        expect(subject().y).toEqual('65%')
      })
    }

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 24,
          height: 24,
          translateX: -12,
          translateY: -12,
        })
      })

      sharedExamplesForTriangles()
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 50,
          height: 50,
          translateX: -25,
          translateY: -25,
        })
      })

      sharedExamplesForTriangles()
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 80,
          height: 80,
          translateX: -40,
          translateY: -40,
        })
      })

      sharedExamplesForTriangles()
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 112,
          height: 112,
          translateX: -56,
          translateY: -56,
        })
      })

      sharedExamplesForTriangles()
    })
  })

  describe('when the shape is a star', () => {
    beforeEach(() => (shape = Shape.Star))

    function sharedExamplesForStars() {
      it('uses "55%" for the Y position', () => {
        expect(subject().y).toEqual('55%')
      })
    }

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 8,
          height: 8,
          translateX: -4,
          translateY: -4,
        })
      })

      sharedExamplesForStars()
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 24,
          height: 24,
          translateX: -12,
          translateY: -12,
        })
      })

      sharedExamplesForStars()
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 44,
          height: 44,
          translateX: -22,
          translateY: -22,
        })
      })

      sharedExamplesForStars()
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 72,
          height: 72,
          translateX: -36,
          translateY: -36,
        })
      })

      sharedExamplesForStars()
    })
  })

  describe('when the shape is a square', () => {
    beforeEach(() => (shape = Shape.Square))

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 60,
          height: 60,
          translateX: -30,
          translateY: -30,
        })
      })
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 108,
          height: 108,
          translateX: -54,
          translateY: -54,
        })
      })
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 142,
          height: 142,
          translateX: -71,
          translateY: -71,
        })
      })
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 200,
          height: 200,
          translateX: -100,
          translateY: -100,
        })
      })
    })
  })

  describe('when the shape is a circle', () => {
    beforeEach(() => (shape = Shape.Circle))

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 54,
          height: 54,
          translateX: -27,
          translateY: -27,
        })
      })
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 100,
          height: 100,
          translateX: -50,
          translateY: -50,
        })
      })
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 132,
          height: 132,
          translateX: -66,
          translateY: -66,
        })
      })
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 180,
          height: 180,
          translateX: -90,
          translateY: -90,
        })
      })
    })
  })

  describe('when the shape is a hexagon', () => {
    beforeEach(() => (shape = Shape.Hexagon))

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 28,
          height: 28,
          translateX: -14,
          translateY: -14,
        })
      })
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 68,
          height: 68,
          translateX: -34,
          translateY: -34,
        })
      })
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 100,
          height: 100,
          translateX: -50,
          translateY: -50,
        })
      })
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 160,
          height: 160,
          translateX: -80,
          translateY: -80,
        })
      })
    })
  })

  describe('when the shape is a octagon', () => {
    beforeEach(() => (shape = Shape.Octagon))

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 36,
          height: 36,
          translateX: -18,
          translateY: -18,
        })
      })
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 80,
          height: 80,
          translateX: -40,
          translateY: -40,
        })
      })
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 110,
          height: 110,
          translateX: -55,
          translateY: -55,
        })
      })
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 180,
          height: 180,
          translateX: -90,
          translateY: -90,
        })
      })
    })
  })

  describe('when the shape is a diamond', () => {
    beforeEach(() => (shape = Shape.Diamond))

    describe('with x-small shape', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 30,
          height: 30,
          translateX: -15,
          translateY: -15,
        })
      })
    })

    describe('with small shape', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 60,
          height: 60,
          translateX: -30,
          translateY: -30,
        })
      })
    })

    describe('with medium shape', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 80,
          height: 80,
          translateX: -40,
          translateY: -40,
        })
      })
    })

    describe('with large shape', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the correct dimension attributes', () => {
        expect(subject()).toMatchObject({
          width: 120,
          height: 120,
          translateX: -60,
          translateY: -60,
        })
      })
    })
  })

  describe('when no transform overrides are set (default case)', () => {
    beforeEach(() => {
      shape = 'default'
    })

    describe('with x-small icon size', () => {
      beforeEach(() => (size = Size.ExtraSmall))

      it('sets the x position', () => {
        expect(subject().x).toEqual('50%')
      })

      it('sets the y position', () => {
        expect(subject().y).toEqual('50%')
      })

      it('sets the width', () => {
        expect(subject().width).toEqual(60)
      })

      it('sets the height', () => {
        expect(subject().height).toEqual(60)
      })

      it('sets the translation in the X direction', () => {
        expect(subject().translateX).toEqual(-30)
      })

      it('sets the translation in the Y direction', () => {
        expect(subject().translateY).toEqual(-30)
      })
    })

    describe('with small icon size', () => {
      beforeEach(() => (size = Size.Small))

      it('sets the x position', () => {
        expect(subject().x).toEqual('50%')
      })

      it('sets the y position', () => {
        expect(subject().y).toEqual('50%')
      })

      it('sets the width', () => {
        expect(subject().width).toEqual(75)
      })

      it('sets the height', () => {
        expect(subject().height).toEqual(75)
      })

      it('sets the translation in the X direction', () => {
        expect(subject().translateX).toEqual(-37.5)
      })

      it('sets the translation in the Y direction', () => {
        expect(subject().translateY).toEqual(-37.5)
      })
    })

    describe('with medium icon size', () => {
      beforeEach(() => (size = Size.Medium))

      it('sets the x position', () => {
        expect(subject().x).toEqual('50%')
      })

      it('sets the y position', () => {
        expect(subject().y).toEqual('50%')
      })

      it('sets the width', () => {
        expect(subject().width).toEqual(80)
      })

      it('sets the height', () => {
        expect(subject().height).toEqual(80)
      })

      it('sets the translation in the X direction', () => {
        expect(subject().translateX).toEqual(-40)
      })

      it('sets the translation in the Y direction', () => {
        expect(subject().translateY).toEqual(-40)
      })
    })

    describe('with large icon size', () => {
      beforeEach(() => (size = Size.Large))

      it('sets the x position', () => {
        expect(subject().x).toEqual('50%')
      })

      it('sets the y position', () => {
        expect(subject().y).toEqual('50%')
      })

      it('sets the width', () => {
        expect(subject().width).toEqual(110)
      })

      it('sets the height', () => {
        expect(subject().height).toEqual(110)
      })

      it('sets the translation in the X direction', () => {
        expect(subject().translateX).toEqual(-55)
      })

      it('sets the translation in the Y direction', () => {
        expect(subject().translateY).toEqual(-55)
      })
    })
  })
})

describe('buildImage', () => {
  describe('when there is no encoded image', () => {
    it('returns undefined', () => {
      expect(buildImage(DEFAULT_SETTINGS)).toBe(undefined)
    })
  })

  describe('when there is an encoded image', () => {
    const baseSettings = {
      ...DEFAULT_SETTINGS,
      width: 1,
      height: 2,
      x: 3,
      y: 4,
      transform: 'translate(5, 6)',
    }

    describe('when the encoded image type is a stock image', () => {
      it('uses the icon settings to set the image attributes', () => {
        const settings = {
          ...baseSettings,
          embedImage: 'data:image/svg+xml;base64,PHN2Zaaaaaaaaa',
          imageSettings: {
            image: 'data:image/svg+xml;base64,PHN2Zaaaaaaaaa',
            mode: 'SingleColor',
          },
        }
        expect(buildImage(settings)).toMatchInlineSnapshot(`
          <g
            clip-path="url(#clip-path-for-embed)"
          >
            <image
              height="2"
              href="data:image/svg+xml;base64,PHN2Zaaaaaaaaa"
              transform="translate(5, 6)"
              width="1"
              x="3"
              y="4"
            />
          </g>
        `)
      })
    })

    describe('when the encoded image type is not a stock image', () => {
      it('uses image attributes computed from the square size', () => {
        const settings = {
          ...baseSettings,
          embedImage: 'data:image/svg+xml;base64,PHN2Zaaaaaaaaa',
          imageSettings: {
            image: 'data:image/svg+xml;base64,PHN2Zbbbbbbbbb',
            mode: 'Course',
          },
        }
        expect(buildImage(settings)).toMatchInlineSnapshot(`
          <g
            clip-path="url(#clip-path-for-embed)"
          >
            <image
              height="114"
              href="data:image/svg+xml;base64,PHN2Zaaaaaaaaa"
              transform="translate(-57, -57)"
              width="114"
              x="50%"
              y="50%"
            />
          </g>
        `)
      })
    })
  })
})
