/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {changeSizeVariant, percentSize} from '../resizeHelpers'

describe('resizeHelpers', () => {
  describe('changeSizeVariant', () => {
    it('returns the current size of the element if the new size variant is auto', () => {
      const elem = {} as HTMLElement
      elem.getBoundingClientRect = jest.fn().mockReturnValue({width: 100, height: 100})
      expect(changeSizeVariant(elem, 'auto')).toEqual({width: 100, height: 100})
    })

    it('returns the current size of the element if the new size variant is pixel', () => {
      const elem = {} as HTMLElement
      elem.getBoundingClientRect = jest.fn().mockReturnValue({width: 100, height: 100})
      expect(changeSizeVariant(elem, 'pixel')).toEqual({width: 100, height: 100})
    })

    it('returns the current width of the element as a percentage of the parent if the new size variant is percent', () => {
      const parent = {
        clientWidth: 200,
        clientHeight: 200,
      } as HTMLElement
      const elem = {} as HTMLElement
      // @ts-expect-error
      elem.offsetParent = parent
      elem.getBoundingClientRect = jest.fn().mockReturnValue({width: 100, height: 120})

      expect(changeSizeVariant(elem, 'percent')).toEqual({width: 50, height: 120})
    })
  })

  describe('percentSize', () => {
    it('returns the percentage of the parent width and height that the element occupies', () => {
      expect(percentSize(200, 100)).toEqual(50)
    })

    it('returns 100% if the element is within 7px of the parent width', () => {
      expect(percentSize(200, 193)).toEqual(100)
    })

    it('returns 100% if the element is within 7px of the parent height', () => {
      expect(percentSize(200, 100)).toEqual(50)
    })
  })
})
