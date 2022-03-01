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

import {transformForShape} from '../image'
import {Shape} from '../shape'
import {Size} from '../constants'

describe('transformShape()', () => {
  let shape, size

  const subject = () => transformForShape(shape, size)

  describe('when the shape is a pentagon', () => {
    beforeEach(() => (shape = Shape.Pentagon))

    it('uses "55%" for the Y position', () => {
      expect(subject().y).toEqual('55%')
    })
  })

  describe('when no transform overrides are set (default case)', () => {
    beforeEach(() => {
      shape = 'default'
    })

    describe('with x-small button size', () => {
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

    describe('with small button size', () => {
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

    describe('with medium button size', () => {
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

    describe('with large button size', () => {
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
