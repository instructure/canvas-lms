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

import fakeENV from '@canvas/test-utils/fakeENV'
import {LtiPlacements, AllLtiPlacements} from '../LtiPlacement'
import {
  isPlacementEnabledByFeatureFlag,
  filterPlacementsByFeatureFlags,
  filterPlacementObjectsByFeatureFlags,
} from '@canvas/lti/model/LtiPlacementFilter'

describe('LtiPlacement Feature Flag Filtering', () => {
  // This is only needed until placement feature flags are removed
  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        top_navigation_placement: true,
        lti_asset_processor: true,
        lti_asset_processor_discussions: true,
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('isPlacementEnabledByFeatureFlag', () => {
    it('returns true for placements without feature flag requirements', () => {
      expect(isPlacementEnabledByFeatureFlag(LtiPlacements.AccountNavigation)).toBe(true)
      expect(isPlacementEnabledByFeatureFlag(LtiPlacements.CourseNavigation)).toBe(true)
      expect(isPlacementEnabledByFeatureFlag(LtiPlacements.GlobalNavigation)).toBe(true)
    })

    it('returns true for top_navigation when feature flag is enabled', () => {
      expect(isPlacementEnabledByFeatureFlag(LtiPlacements.TopNavigation)).toBe(true)
    })

    it('returns true for ActivityAssetProcessor when feature flag is enabled', () => {
      expect(isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessor)).toBe(true)
    })

    it('returns true for ActivityAssetProcessorContribution when feature flag is enabled', () => {
      expect(
        isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessorContribution),
      ).toBe(true)
    })

    describe('when top_navigation_placement feature flag is disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: false,
            lti_asset_processor: true,
            lti_asset_processor_discussions: true,
          },
        })
      })

      it('returns false for top_navigation placement', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.TopNavigation)).toBe(false)
      })

      it('still returns true for placements without feature flag requirements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.AccountNavigation)).toBe(true)
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.CourseNavigation)).toBe(true)
      })

      it('still returns true for other feature-flagged placements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessor)).toBe(true)
        expect(
          isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessorContribution),
        ).toBe(true)
      })
    })

    describe('when lti_asset_processor feature flag is disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: true,
            lti_asset_processor: false,
            lti_asset_processor_discussions: true,
          },
        })
      })

      it('returns false for ActivityAssetProcessor placement', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessor)).toBe(false)
      })

      it('still returns true for other placements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.TopNavigation)).toBe(true)
        expect(
          isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessorContribution),
        ).toBe(true)
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.CourseNavigation)).toBe(true)
      })
    })

    describe('when lti_asset_processor_discussions feature flag is disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: true,
            lti_asset_processor: true,
            lti_asset_processor_discussions: false,
          },
        })
      })

      it('returns false for ActivityAssetProcessorContribution placement', () => {
        expect(
          isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessorContribution),
        ).toBe(false)
      })

      it('still returns true for other placements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.TopNavigation)).toBe(true)
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessor)).toBe(true)
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.CourseNavigation)).toBe(true)
      })
    })

    describe('when all placement feature flags are disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: false,
            lti_asset_processor: false,
            lti_asset_processor_discussions: false,
          },
        })
      })

      it('returns false for all feature-flagged placements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.TopNavigation)).toBe(false)
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessor)).toBe(false)
        expect(
          isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessorContribution),
        ).toBe(false)
      })

      it('still returns true for placements without feature flag requirements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.AccountNavigation)).toBe(true)
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.CourseNavigation)).toBe(true)
      })
    })

    describe('when feature flags are undefined', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {},
        })
      })

      it('returns false for feature-flagged placements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.TopNavigation)).toBe(false)
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.ActivityAssetProcessor)).toBe(false)
      })

      it('returns true for placements without feature flag requirements', () => {
        expect(isPlacementEnabledByFeatureFlag(LtiPlacements.CourseNavigation)).toBe(true)
      })
    })
  })

  describe('filterPlacementsByFeatureFlags', () => {
    it('returns all placements when all feature flags are enabled', () => {
      const result = filterPlacementsByFeatureFlags(AllLtiPlacements)
      expect(result).toHaveLength(AllLtiPlacements.length)
      expect(result).toContain(LtiPlacements.TopNavigation)
      expect(result).toContain(LtiPlacements.ActivityAssetProcessor)
      expect(result).toContain(LtiPlacements.ActivityAssetProcessorContribution)
    })

    it('filters out only disabled placements', () => {
      const placements = [
        LtiPlacements.AccountNavigation,
        LtiPlacements.TopNavigation,
        LtiPlacements.CourseNavigation,
      ]
      const result = filterPlacementsByFeatureFlags(placements)
      expect(result).toHaveLength(3)
      expect(result).toContain(LtiPlacements.TopNavigation)
    })

    describe('when top_navigation_placement feature flag is disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: false,
            lti_asset_processor: true,
            lti_asset_processor_discussions: true,
          },
        })
      })

      it('filters out top_navigation placement', () => {
        const placements = [
          LtiPlacements.AccountNavigation,
          LtiPlacements.TopNavigation,
          LtiPlacements.CourseNavigation,
        ]
        const result = filterPlacementsByFeatureFlags(placements)
        expect(result).toHaveLength(2)
        expect(result).not.toContain(LtiPlacements.TopNavigation)
        expect(result).toContain(LtiPlacements.AccountNavigation)
        expect(result).toContain(LtiPlacements.CourseNavigation)
      })

      it('keeps other feature-flagged placements', () => {
        const placements = [
          LtiPlacements.TopNavigation,
          LtiPlacements.ActivityAssetProcessor,
          LtiPlacements.ActivityAssetProcessorContribution,
        ]
        const result = filterPlacementsByFeatureFlags(placements)
        expect(result).toHaveLength(2)
        expect(result).not.toContain(LtiPlacements.TopNavigation)
        expect(result).toContain(LtiPlacements.ActivityAssetProcessor)
        expect(result).toContain(LtiPlacements.ActivityAssetProcessorContribution)
      })

      it('filters out top_navigation from AllLtiPlacements', () => {
        const result = filterPlacementsByFeatureFlags(AllLtiPlacements)
        expect(result).toHaveLength(AllLtiPlacements.length - 1)
        expect(result).not.toContain(LtiPlacements.TopNavigation)
      })
    })

    describe('when multiple feature flags are disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: false,
            lti_asset_processor: false,
            lti_asset_processor_discussions: true,
          },
        })
      })

      it('filters out all disabled feature-flagged placements', () => {
        const placements = [
          LtiPlacements.TopNavigation,
          LtiPlacements.ActivityAssetProcessor,
          LtiPlacements.ActivityAssetProcessorContribution,
          LtiPlacements.CourseNavigation,
        ]
        const result = filterPlacementsByFeatureFlags(placements)
        expect(result).toHaveLength(2)
        expect(result).not.toContain(LtiPlacements.TopNavigation)
        expect(result).not.toContain(LtiPlacements.ActivityAssetProcessor)
        expect(result).toContain(LtiPlacements.ActivityAssetProcessorContribution)
        expect(result).toContain(LtiPlacements.CourseNavigation)
      })
    })

    it('handles empty arrays', () => {
      const result = filterPlacementsByFeatureFlags([])
      expect(result).toHaveLength(0)
    })
  })

  describe('filterPlacementObjectsByFeatureFlags', () => {
    type PlacementConfig = {
      placement: string
      enabled: boolean
      label?: string
    }

    it('returns all placement objects when all feature flags are enabled', () => {
      const placements: PlacementConfig[] = [
        {placement: LtiPlacements.AccountNavigation, enabled: true},
        {placement: LtiPlacements.TopNavigation, enabled: true},
        {placement: LtiPlacements.CourseNavigation, enabled: true},
      ]
      const result = filterPlacementObjectsByFeatureFlags(placements)
      expect(result).toHaveLength(3)
      expect(result).toContainEqual({placement: LtiPlacements.TopNavigation, enabled: true})
    })

    it('preserves all properties of placement objects', () => {
      const placements: PlacementConfig[] = [
        {placement: LtiPlacements.TopNavigation, enabled: true, label: 'Top Nav'},
        {placement: LtiPlacements.CourseNavigation, enabled: false, label: 'Course Nav'},
      ]
      const result = filterPlacementObjectsByFeatureFlags(placements)
      expect(result).toHaveLength(2)
      expect(result[0]).toEqual({
        placement: LtiPlacements.TopNavigation,
        enabled: true,
        label: 'Top Nav',
      })
      expect(result[1]).toEqual({
        placement: LtiPlacements.CourseNavigation,
        enabled: false,
        label: 'Course Nav',
      })
    })

    describe('when top_navigation_placement feature flag is disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: false,
            lti_asset_processor: true,
            lti_asset_processor_discussions: true,
          },
        })
      })

      it('filters out placement objects with top_navigation', () => {
        const placements: PlacementConfig[] = [
          {placement: LtiPlacements.AccountNavigation, enabled: true},
          {placement: LtiPlacements.TopNavigation, enabled: true},
          {placement: LtiPlacements.CourseNavigation, enabled: true},
        ]
        const result = filterPlacementObjectsByFeatureFlags(placements)
        expect(result).toHaveLength(2)
        expect(result.some(p => p.placement === LtiPlacements.TopNavigation)).toBe(false)
        expect(result.some(p => p.placement === LtiPlacements.AccountNavigation)).toBe(true)
        expect(result.some(p => p.placement === LtiPlacements.CourseNavigation)).toBe(true)
      })

      it('keeps other feature-flagged placement objects', () => {
        const placements: PlacementConfig[] = [
          {placement: LtiPlacements.TopNavigation, enabled: true},
          {placement: LtiPlacements.ActivityAssetProcessor, enabled: true},
          {placement: LtiPlacements.ActivityAssetProcessorContribution, enabled: false},
        ]
        const result = filterPlacementObjectsByFeatureFlags(placements)
        expect(result).toHaveLength(2)
        expect(result.some(p => p.placement === LtiPlacements.TopNavigation)).toBe(false)
        expect(result.some(p => p.placement === LtiPlacements.ActivityAssetProcessor)).toBe(true)
        expect(
          result.some(p => p.placement === LtiPlacements.ActivityAssetProcessorContribution),
        ).toBe(true)
      })
    })

    describe('when multiple feature flags are disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: false,
            lti_asset_processor: false,
            lti_asset_processor_discussions: true,
          },
        })
      })

      it('filters out all objects with disabled feature-flagged placements', () => {
        const placements: PlacementConfig[] = [
          {placement: LtiPlacements.TopNavigation, enabled: true},
          {placement: LtiPlacements.ActivityAssetProcessor, enabled: true},
          {placement: LtiPlacements.ActivityAssetProcessorContribution, enabled: true},
          {placement: LtiPlacements.CourseNavigation, enabled: true},
        ]
        const result = filterPlacementObjectsByFeatureFlags(placements)
        expect(result).toHaveLength(2)
        expect(result.some(p => p.placement === LtiPlacements.TopNavigation)).toBe(false)
        expect(result.some(p => p.placement === LtiPlacements.ActivityAssetProcessor)).toBe(false)
        expect(
          result.some(p => p.placement === LtiPlacements.ActivityAssetProcessorContribution),
        ).toBe(true)
        expect(result.some(p => p.placement === LtiPlacements.CourseNavigation)).toBe(true)
      })
    })

    it('handles empty arrays', () => {
      const result = filterPlacementObjectsByFeatureFlags([])
      expect(result).toHaveLength(0)
    })

    it('works with different object shapes', () => {
      type DifferentShape = {
        placement: string
        customProp: number
      }
      const placements: DifferentShape[] = [
        {placement: LtiPlacements.TopNavigation, customProp: 123},
        {placement: LtiPlacements.CourseNavigation, customProp: 456},
      ]
      const result = filterPlacementObjectsByFeatureFlags(placements)
      expect(result).toHaveLength(2)
      expect(result[0].customProp).toBe(123)
      expect(result[1].customProp).toBe(456)
    })
  })
})
