/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {BREAKPOINTS, responsiveQuerySizes} from '../index'

describe('@canvas/breakpoints', () => {
  describe('BREAKPOINTS', () => {
    it('defines standard mobile breakpoint', () => {
      expect(BREAKPOINTS.mobile).toBe(767)
    })

    it('defines standard tablet breakpoint', () => {
      expect(BREAKPOINTS.tablet).toBe(1023)
    })

    it('defines standard desktop breakpoint', () => {
      expect(BREAKPOINTS.desktop).toBe(1024)
    })

    it('has mutually exclusive boundaries', () => {
      expect(BREAKPOINTS.tablet).toBe(BREAKPOINTS.desktop - 1)
      expect(BREAKPOINTS.mobile).toBe(768 - 1)
    })
  })

  describe('responsiveQuerySizes', () => {
    describe('single breakpoint', () => {
      it('returns only mobile when mobile is true', () => {
        const result = responsiveQuerySizes({mobile: true})
        expect(result).toEqual({
          mobile: {maxWidth: '767px'},
        })
      })

      it('returns only tablet when tablet is true', () => {
        const result = responsiveQuerySizes({tablet: true})
        expect(result).toEqual({
          tablet: {minWidth: '0px', maxWidth: '1023px'},
        })
      })

      it('returns only desktop when desktop is true', () => {
        const result = responsiveQuerySizes({desktop: true})
        expect(result).toEqual({
          desktop: {minWidth: '768px'},
        })
      })
    })

    describe('two breakpoints', () => {
      it('returns mobile + desktop with no overlap', () => {
        const result = responsiveQuerySizes({mobile: true, desktop: true})
        expect(result).toEqual({
          mobile: {maxWidth: '767px'},
          desktop: {minWidth: '768px'},
        })
      })

      it('returns tablet + desktop with proper boundary', () => {
        const result = responsiveQuerySizes({tablet: true, desktop: true})
        expect(result).toEqual({
          tablet: {minWidth: '0px', maxWidth: '1023px'},
          desktop: {minWidth: '1024px'},
        })
      })

      it('returns mobile + tablet with no overlap', () => {
        const result = responsiveQuerySizes({mobile: true, tablet: true})
        expect(result).toEqual({
          mobile: {maxWidth: '767px'},
          tablet: {minWidth: '768px', maxWidth: '1023px'},
        })
      })
    })

    describe('all three breakpoints', () => {
      it('returns mutually exclusive breakpoints', () => {
        const result = responsiveQuerySizes({mobile: true, tablet: true, desktop: true})
        expect(result).toEqual({
          mobile: {maxWidth: '767px'},
          tablet: {minWidth: '768px', maxWidth: '1023px'},
          desktop: {minWidth: '1024px'},
        })
      })
    })

    describe('no breakpoints', () => {
      it('returns empty object when no flags are set', () => {
        const result = responsiveQuerySizes({})
        expect(result).toEqual({})
      })

      it('returns empty object when called with no arguments', () => {
        const result = responsiveQuerySizes()
        expect(result).toEqual({})
      })
    })

    describe('breakpoint boundaries', () => {
      it('ensures mobile and tablet do not overlap when both are specified', () => {
        const result = responsiveQuerySizes({mobile: true, tablet: true})
        const mobileMax = parseInt(result.mobile!.maxWidth!)
        const tabletMin = parseInt(result.tablet!.minWidth!)

        // Mobile max should be 767, tablet min should be 768 (no overlap)
        expect(tabletMin).toBe(mobileMax + 1)
      })

      it('ensures tablet and desktop do not overlap when both are specified', () => {
        const result = responsiveQuerySizes({tablet: true, desktop: true})
        const tabletMax = parseInt(result.tablet!.maxWidth!)
        const desktopMin = parseInt(result.desktop!.minWidth!)

        // Tablet max should be 1023, desktop min should be 1024 (no overlap)
        expect(desktopMin).toBe(tabletMax + 1)
      })

      it('ensures desktop starts at correct point based on whether tablet is specified', () => {
        const withTablet = responsiveQuerySizes({tablet: true, desktop: true})
        const withoutTablet = responsiveQuerySizes({mobile: true, desktop: true})

        expect(withTablet.desktop!.minWidth).toBe('1024px')
        expect(withoutTablet.desktop!.minWidth).toBe('768px')
      })
    })
  })
})
