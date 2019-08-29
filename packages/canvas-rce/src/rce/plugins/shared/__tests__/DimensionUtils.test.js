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

import * as DimensionsUtils from '../DimensionUtils'

describe('RCE > Plugins > Shared > DimensionsUtils', () => {
  describe('.scaleForHeight()', () => {
    let constraints

    beforeEach(() => {
      constraints = {minHeight: 50, minWidth: 50}
    })

    it('sets the height to the target height', () => {
      const dimensions = DimensionsUtils.scaleForHeight(100, 200, 300, constraints)
      expect(dimensions.height).toEqual(300)
    })

    it('scales the width proportionally with the height', () => {
      const dimensions = DimensionsUtils.scaleForHeight(100, 200, 300, constraints)
      expect(dimensions.width).toEqual(150)
    })

    describe('when the target height is below minimum height', () => {
      it('sets the height to the minimum height', () => {
        constraints = {minHeight: 150, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, 148, constraints)
        expect(dimensions.height).toEqual(150)
      })

      it('scales the width proportionally with the minimum height', () => {
        constraints = {minHeight: 150, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, 148, constraints)
        expect(dimensions.width).toEqual(75)
      })
    })

    describe('when no minimum height is set', () => {
      it('uses zero as the minimum height', () => {
        constraints = {minHeight: 150, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, -1)
        expect(dimensions.height).toEqual(0)
      })

      it('scales the width proportionally with the minimum height', () => {
        constraints = {minHeight: 150, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, -1)
        expect(dimensions.width).toEqual(0)
      })
    })

    describe('when the target height scales the width below minimum width', () => {
      it('scales the height proportionally with the minimum width', () => {
        constraints = {minHeight: 50, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, 60, constraints)
        expect(dimensions.height).toEqual(100)
      })

      it('sets the width to the minimum width', () => {
        constraints = {minHeight: 50, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, 60, constraints)
        expect(dimensions.width).toEqual(50)
      })
    })

    describe('when the target height scales the width fractionally below minimum width', () => {
      it('scales the height proportionally with the minimum width', () => {
        constraints = {minHeight: 50, minWidth: 50}
        // 100 x 300 => 49.66 x 149
        const dimensions = DimensionsUtils.scaleForHeight(100, 300, 149, constraints)
        expect(dimensions.height).toEqual(150)
      })

      it('sets the width to the minimum width', () => {
        constraints = {minHeight: 50, minWidth: 50}
        // 100 x 300 => 49.66 x 149
        const dimensions = DimensionsUtils.scaleForHeight(100, 300, 149, constraints)
        expect(dimensions.width).toEqual(50)
      })
    })

    describe('when the target height and scaled width are below minimums', () => {
      describe('when the height can be reduced further than the width', () => {
        it('scales the height proportionally with the minimum width', () => {
          constraints = {minHeight: 100, minWidth: 75}
          const dimensions = DimensionsUtils.scaleForHeight(100, 200, 98, constraints)
          expect(dimensions.height).toEqual(150)
        })

        it('sets the width to the minimum width', () => {
          constraints = {minHeight: 100, minWidth: 75}
          const dimensions = DimensionsUtils.scaleForHeight(100, 200, 98, constraints)
          expect(dimensions.width).toEqual(75)
        })
      })

      describe('when the width can be reduced further than the height', () => {
        it('sets the height to the minimum height', () => {
          constraints = {minHeight: 75, minWidth: 100}
          const dimensions = DimensionsUtils.scaleForHeight(200, 100, 70, constraints)
          expect(dimensions.height).toEqual(75)
        })

        it('scales the width proportionally with the minimum height', () => {
          constraints = {minHeight: 75, minWidth: 100}
          const dimensions = DimensionsUtils.scaleForHeight(200, 100, 70, constraints)
          expect(dimensions.width).toEqual(150)
        })
      })
    })

    describe('when the scaled width has a small fraction', () => {
      it('sets the height to the target height', () => {
        // 150 x 200 => 149.25 x 199
        const dimensions = DimensionsUtils.scaleForHeight(150, 200, 199, constraints)
        expect(dimensions.height).toEqual(199)
      })

      it('rounds the scaled width down to a whole number', () => {
        const dimensions = DimensionsUtils.scaleForHeight(150, 200, 199, constraints)
        expect(dimensions.width).toEqual(149)
      })
    })

    describe('when the scaled width has a large fraction', () => {
      it('sets the height to the target height', () => {
        // 150 x 200 => 147.75 x 197
        const dimensions = DimensionsUtils.scaleForHeight(150, 200, 197, constraints)
        expect(dimensions.height).toEqual(197)
      })

      it('rounds the scaled width up to a whole number', () => {
        const dimensions = DimensionsUtils.scaleForHeight(150, 200, 197, constraints)
        expect(dimensions.width).toEqual(148)
      })
    })

    describe('when the target height is null', () => {
      it('sets the height to null', () => {
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, null, constraints)
        expect(dimensions.height).toBeNull()
      })

      it('sets the width to null', () => {
        const dimensions = DimensionsUtils.scaleForHeight(100, 200, null, constraints)
        expect(dimensions.width).toBeNull()
      })
    })
  })

  describe('.scaleForWidth()', () => {
    let constraints

    beforeEach(() => {
      constraints = {minHeight: 50, minWidth: 50}
    })

    it('sets the width to the target width', () => {
      const dimensions = DimensionsUtils.scaleForWidth(200, 100, 300, constraints)
      expect(dimensions.width).toEqual(300)
    })

    it('scales the height proportionally with the width', () => {
      const dimensions = DimensionsUtils.scaleForWidth(200, 100, 300, constraints)
      expect(dimensions.height).toEqual(150)
    })

    describe('when the target width is below minimum width', () => {
      it('sets the width to the minimum width', () => {
        constraints = {minHeight: 50, minWidth: 150}
        const dimensions = DimensionsUtils.scaleForWidth(200, 100, 148, constraints)
        expect(dimensions.width).toEqual(150)
      })

      it('scales the height proportionally with the minimum width', () => {
        constraints = {minHeight: 50, minWidth: 150}
        const dimensions = DimensionsUtils.scaleForWidth(200, 100, 148, constraints)
        expect(dimensions.height).toEqual(75)
      })
    })

    describe('when no minimum width is set', () => {
      it('uses zero as the minimum width', () => {
        constraints = {minHeight: 150, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForWidth(100, 200, -1)
        expect(dimensions.width).toEqual(0)
      })

      it('scales the height proportionally with the minimum width', () => {
        constraints = {minHeight: 150, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForWidth(100, 200, -1)
        expect(dimensions.height).toEqual(0)
      })
    })

    describe('when the target width scales the height below minimum height', () => {
      it('scales the width proportionally with the minimum height', () => {
        constraints = {minHeight: 50, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForWidth(200, 100, 60, constraints)
        expect(dimensions.width).toEqual(100)
      })

      it('sets the height to the minimum height', () => {
        constraints = {minHeight: 50, minWidth: 50}
        const dimensions = DimensionsUtils.scaleForWidth(200, 100, 60, constraints)
        expect(dimensions.height).toEqual(50)
      })
    })

    describe('when the target width scales the height fractionally below minimum height', () => {
      it('scales the width proportionally with the minimum height', () => {
        constraints = {minHeight: 50, minWidth: 50}
        // 300 x 100 => 149 x 49.66
        const dimensions = DimensionsUtils.scaleForWidth(300, 100, 149, constraints)
        expect(dimensions.width).toEqual(150)
      })

      it('sets the height to the minimum height', () => {
        constraints = {minHeight: 50, minWidth: 50}
        // 300 x 100 => 149 x 49.66
        const dimensions = DimensionsUtils.scaleForWidth(300, 100, 149, constraints)
        expect(dimensions.height).toEqual(50)
      })
    })

    describe('when the target width and scaled height are below minimums', () => {
      describe('when the width can be reduced further than the height', () => {
        it('scales the width proportionally with the minimum height', () => {
          constraints = {minHeight: 75, minWidth: 100}
          const dimensions = DimensionsUtils.scaleForWidth(200, 100, 98, constraints)
          expect(dimensions.width).toEqual(150)
        })

        it('sets the height to the minimum height', () => {
          constraints = {minHeight: 75, minWidth: 100}
          const dimensions = DimensionsUtils.scaleForWidth(200, 100, 98, constraints)
          expect(dimensions.height).toEqual(75)
        })
      })

      describe('when the height can be reduced further than the width', () => {
        it('sets the width to the minimum width', () => {
          constraints = {minHeight: 100, minWidth: 75}
          const dimensions = DimensionsUtils.scaleForWidth(100, 200, 70, constraints)
          expect(dimensions.width).toEqual(75)
        })

        it('scales the height proportionally with the minimum width', () => {
          constraints = {minHeight: 100, minWidth: 75}
          const dimensions = DimensionsUtils.scaleForWidth(100, 200, 70, constraints)
          expect(dimensions.height).toEqual(150)
        })
      })
    })

    describe('when the scaled height has a small fraction', () => {
      it('sets the width to the target width', () => {
        // 150 x 200 => 149.25 x 199
        const dimensions = DimensionsUtils.scaleForWidth(200, 150, 199, constraints)
        expect(dimensions.width).toEqual(199)
      })

      it('rounds the scaled height down to a whole number', () => {
        const dimensions = DimensionsUtils.scaleForWidth(200, 150, 199, constraints)
        expect(dimensions.height).toEqual(149)
      })
    })

    describe('when the scaled height has a large fraction', () => {
      it('sets the width to the target width', () => {
        // 150 x 200 => 147.75 x 197
        const dimensions = DimensionsUtils.scaleForWidth(200, 150, 197, constraints)
        expect(dimensions.width).toEqual(197)
      })

      it('rounds the scaled height up to a whole number', () => {
        const dimensions = DimensionsUtils.scaleForWidth(200, 150, 197, constraints)
        expect(dimensions.height).toEqual(148)
      })
    })

    describe('when the target width is null', () => {
      it('sets the width to null', () => {
        const dimensions = DimensionsUtils.scaleForHeight(200, 100, null, constraints)
        expect(dimensions.width).toBeNull()
      })

      it('sets the height to null', () => {
        const dimensions = DimensionsUtils.scaleForWidth(200, 100, null, constraints)
        expect(dimensions.height).toBeNull()
      })
    })
  })
})
