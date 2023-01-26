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

import {
  calculateScaleRatio,
  calculateScalePercentage,
  calculateRotation,
  getNearestRectAngle,
} from '../utils'

describe('calculateScaleRatio()', () => {
  it('when ratio exceeds maximum ratio', () => {
    const result = calculateScaleRatio(2.5)
    expect(result).toEqual(2)
  })

  it('when ratio exceeds minimum ratio', () => {
    const result = calculateScaleRatio(0.5)
    expect(result).toEqual(1)
  })

  it('when ratio is between thresholds', () => {
    const result = calculateScaleRatio(1.5)
    expect(result).toEqual(1.5)
  })
})

describe('calculateScalePercentage()', () => {
  it('when ratio exceeds maximum percentage', () => {
    const result = calculateScalePercentage(250)
    expect(result).toEqual(200)
  })

  it('when ratio exceeds minimum percentage', () => {
    const result = calculateScalePercentage(50)
    expect(result).toEqual(100)
  })

  it('when ratio is between thresholds', () => {
    const result = calculateScalePercentage(150)
    expect(result).toEqual(150)
  })
})

describe('calculateRotation()', () => {
  it('when rotation angle is 360', () => {
    const result = calculateRotation(360)
    expect(result).toEqual(0)
  })

  it('when rotation angle is -360', () => {
    const result = calculateRotation(-360)
    expect(result).toEqual(0)
  })

  it('when rotation angle exceeds 360', () => {
    const result = calculateRotation(375)
    expect(result).toEqual(15)
  })

  it('when rotation angle is lower than -360', () => {
    const result = calculateRotation(-375)
    expect(result).toEqual(-15)
  })

  it('when rotation angle is between thresholds positive', () => {
    const result = calculateRotation(175)
    expect(result).toEqual(175)
  })

  it('when rotation angle is between thresholds negative', () => {
    const result = calculateRotation(-175)
    expect(result).toEqual(-175)
  })

  it('when rotation angle is zero', () => {
    const result = calculateRotation(0)
    expect(result).toEqual(0)
  })
})

describe('getNearestRectAngle()', () => {
  describe('when should rotate to left', () => {
    it('1º', () => {
      const result = getNearestRectAngle(1, true)
      expect(result).toEqual(90)
    })

    it('45º', () => {
      const result = getNearestRectAngle(45, true)
      expect(result).toEqual(90)
    })

    it('89º', () => {
      const result = getNearestRectAngle(89, true)
      expect(result).toEqual(90)
    })

    describe('and rotation angle is divisible by 90', () => {
      it('0º', () => {
        const result = getNearestRectAngle(0, true)
        expect(result).toEqual(0)
      })

      it('90º', () => {
        const result = getNearestRectAngle(90, true)
        expect(result).toEqual(90)
      })

      it('180º', () => {
        const result = getNearestRectAngle(180, true)
        expect(result).toEqual(180)
      })

      it('270º', () => {
        const result = getNearestRectAngle(270, true)
        expect(result).toEqual(270)
      })
    })
  })

  describe('when should rotate to right', () => {
    it('1º', () => {
      const result = getNearestRectAngle(1, false)
      expect(result).toEqual(0)
    })

    it('45º', () => {
      const result = getNearestRectAngle(45, false)
      expect(result).toEqual(0)
    })

    it('89º', () => {
      const result = getNearestRectAngle(89, false)
      expect(result).toEqual(0)
    })

    describe('and rotation angle is divisible by 90', () => {
      it('0º', () => {
        const result = getNearestRectAngle(0, false)
        expect(result).toEqual(0)
      })

      it('90º', () => {
        const result = getNearestRectAngle(90, false)
        expect(result).toEqual(90)
      })

      it('180º', () => {
        const result = getNearestRectAngle(180, false)
        expect(result).toEqual(180)
      })

      it('270º', () => {
        const result = getNearestRectAngle(270, false)
        expect(result).toEqual(270)
      })
    })
  })
})
