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
  getRandomInt,
  getWeightedPropIndex,
  generateParticle,
  getBrandingColors,
  getProps,
} from '../confetti.utils'
import type {ConfettiObject} from '../../types'

describe('confetti.utils', () => {
  describe('getRandomInt', () => {
    it('should return a random number between 0 and the limit', () => {
      const result = getRandomInt(10)
      expect(result).toBeGreaterThanOrEqual(0)
      expect(result).toBeLessThanOrEqual(10)
    })

    it('should return a random number between 0 and the limit when floor is true', () => {
      const result = getRandomInt(10, true)
      expect(result).toBeGreaterThanOrEqual(0)
      expect(result).toBeLessThanOrEqual(10)
    })

    it('should return a random number between 0 and 1 when limit is 0', () => {
      const result = getRandomInt(0)
      expect(result).toBeGreaterThanOrEqual(0)
      expect(result).toBeLessThanOrEqual(1)
    })
  })

  describe('getWeightedPropIndex', () => {
    it('should return a random index based on the weight of the props', () => {
      const props = [{weight: 1}, {weight: 2}, {weight: 3}, {weight: 4}, {weight: 5}, {weight: 6}]
      const result = getWeightedPropIndex(props, 21)
      expect(result).toBeGreaterThanOrEqual(0)
      expect(result).toBeLessThanOrEqual(5)
    })

    it('should return a random index based on the weight of the props when the total weight is 0', () => {
      const props = [{weight: 0}, {weight: 0}, {weight: 0}, {weight: 0}, {weight: 0}, {weight: 0}]
      const result = getWeightedPropIndex(props, 0)
      expect(result).toBeGreaterThanOrEqual(0)
      expect(result).toBeLessThanOrEqual(5)
    })
  })

  describe('generateParticle', () => {
    it('should return a particle with a prop, x, y, color, rotation, and speed', () => {
      const props = [{weight: 1}, {weight: 2}, {weight: 3}, {weight: 4}, {weight: 5}, {weight: 6}]
      const colors = [[0, 0, 0]]
      const speed = 1
      const result = generateParticle(props, colors, speed)
      expect(result.prop).toBeDefined()
      expect(result.x).toBeDefined()
      expect(result.y).toBeDefined()
      expect(result.color).toBeDefined()
      expect(result.rotation).toBeDefined()
      expect(result.speed).toBeDefined()
    })

    it('should return a particle with a src and size when the prop is an object', () => {
      const props = [{weight: 1, src: 'test', size: 1}]
      const colors = [[0, 0, 0]]
      const speed = 1
      const result = generateParticle(props, colors, speed)
      expect(result.src).toBeDefined()
      expect(result.size).toBeDefined()
    })
  })

  describe('getBrandingColors', () => {
    it('should return null when confetti branding is disabled', () => {
      // @ts-expect-error
      window.ENV = {confetti_branding_enabled: false}
      expect(getBrandingColors()).toBeNull()
    })

    it('should return null when confetti branding is enabled but there is no active brand config', () => {
      // @ts-expect-error
      window.ENV = {confetti_branding_enabled: true}
      expect(getBrandingColors()).toBeNull()
    })

    it('should return colors when confetti branding is enabled and there are active brand config variables', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: true,
        active_brand_config: {
          variables: {
            'ic-brand-primary': '#000000',
            'ic-brand-global-nav-bgd': '#000000',
          },
        },
      }
      expect(getBrandingColors()).toEqual([
        [0, 0, 0],
        [0, 0, 0],
      ])
    })

    it('provides only the secondary color when primary is not specified', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: true,
        active_brand_config: {
          variables: {
            'ic-brand-global-nav-bgd': '#ffffff',
          },
        },
      }
      expect(getBrandingColors()).toEqual([[255, 255, 255]])
    })

    it('provides both colors when both are specified', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: true,
        active_brand_config: {
          variables: {
            'ic-brand-primary': '#000000',
            'ic-brand-global-nav-bgd': '#ffffff',
          },
        },
      }
      expect(getBrandingColors()).toEqual([
        [0, 0, 0],
        [255, 255, 255],
      ])
    })

    it('does not provide any colors if none are specified', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: true,
        active_brand_config: {
          variables: {},
        },
      }
      expect(getBrandingColors()).toEqual(null)
    })

    describe('confetti_branding flag is disabled', () => {
      it('does not provide any custom colors', () => {
        // @ts-expect-error
        window.ENV = {
          confetti_branding_enabled: false,
          active_brand_config: {
            variables: {
              'ic-brand-primary': '#000000',
              'ic-brand-global-nav-bgd': '#ffffff',
            },
          },
        }
        expect(getBrandingColors()).toEqual(null)
      })
    })
  })

  describe('logo', () => {
    it('returns a logo when branding enabled', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: true,
        active_brand_config: {variables: {'ic-brand-header-image': 'test'}},
      }
      expect(getProps()[2]).toBeDefined()
    })

    it('does not return a logo when branding disabled', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: false,
        active_brand_config: {variables: {'ic-brand-header-image': 'test'}},
      }
      expect(getProps()[2]).not.toBeDefined()
    })
  })

  describe('getProps', () => {
    it('return a square prop', () => {
      expect(getProps()[0]).toEqual('square')
    })

    it('returns a random confetti flavor', () => {
      const secondProp = getProps()[1] as ConfettiObject
      expect(secondProp.type).toBeDefined()
    })

    it('return a brand logo when branding enabled', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: true,
        active_brand_config: {variables: {'ic-brand-header-image': 'test'}},
      }
      const prop = getProps()[2]
      // @ts-expect-error
      expect(prop.src).toBe('test')
    })

    it('does not return a brand logo when branding disabled', () => {
      // @ts-expect-error
      window.ENV = {
        confetti_branding_enabled: false,
        active_brand_config: {variables: {'ic-brand-header-image': 'test'}},
      }
      expect(getProps()[2]).not.toBeDefined()
    })
  })
})
