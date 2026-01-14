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

import type {FeatureConfig, FeatureLifecycle} from '../featureRegistry'

const createMockLifecycle = (overrides: Partial<FeatureLifecycle> = {}): FeatureLifecycle => ({
  mount: vi.fn(),
  unmount: vi.fn(),
  ...overrides,
})

const createMockConfig = (overrides: Partial<FeatureConfig> = {}): FeatureConfig => ({
  name: 'test-feature',
  feature: () => createMockLifecycle(),
  ...overrides,
})

describe('FeatureRegistry', () => {
  beforeEach(() => {
    // Reset the registry before each test by re-importing
    vi.resetModules()
    // Clear any existing CANVAS object
    delete (window as any).CANVAS
  })

  describe('registerFeature', () => {
    it('registers a feature', async () => {
      await import('../featureRegistry')

      const config = createMockConfig({name: 'my-feature'})
      window.CANVAS.registerFeature(config)

      const features = window.CANVAS.getFeatures()
      expect(features.has('my-feature')).toBe(true)
    })

    it('ignores duplicate registration with same name', async () => {
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
      await import('../featureRegistry')

      window.CANVAS.registerFeature(createMockConfig({name: 'dup-feature'}))
      window.CANVAS.registerFeature(createMockConfig({name: 'dup-feature'}))

      const features = window.CANVAS.getFeatures()
      expect(features.size).toBe(1)
      expect(consoleSpy).toHaveBeenCalledWith(
        'Feature "dup-feature" already registered, ignoring duplicate',
      )

      consoleSpy.mockRestore()
    })

    it('mounts feature immediately if startFeatures already called', async () => {
      await import('../featureRegistry')

      const mountFn = vi.fn()
      await window.CANVAS.startFeatures()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'late-feature',
          feature: () => createMockLifecycle({mount: mountFn}),
        }),
      )

      // Wait for async mount
      await new Promise(resolve => setTimeout(resolve, 0))

      expect(mountFn).toHaveBeenCalled()
    })
  })

  describe('startFeatures', () => {
    it('mounts all registered features', async () => {
      await import('../featureRegistry')

      const mount1 = vi.fn()
      const mount2 = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'feature-1',
          feature: () => createMockLifecycle({mount: mount1}),
        }),
      )
      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'feature-2',
          feature: () => createMockLifecycle({mount: mount2}),
        }),
      )

      await window.CANVAS.startFeatures()

      expect(mount1).toHaveBeenCalled()
      expect(mount2).toHaveBeenCalled()
    })

    it('calls bootstrap before mount', async () => {
      await import('../featureRegistry')

      const callOrder: string[] = []
      const bootstrap = vi.fn(() => {
        callOrder.push('bootstrap')
      })
      const mount = vi.fn(() => {
        callOrder.push('mount')
      })

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'bootstrap-feature',
          feature: () => createMockLifecycle({bootstrap, mount}),
        }),
      )

      await window.CANVAS.startFeatures()

      expect(callOrder).toEqual(['bootstrap', 'mount'])
    })

    it('only calls bootstrap once even if mount is called multiple times', async () => {
      await import('../featureRegistry')

      const bootstrap = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'once-bootstrap',
          feature: () => createMockLifecycle({bootstrap}),
        }),
      )

      await window.CANVAS.startFeatures()

      expect(bootstrap).toHaveBeenCalledTimes(1)
    })
  })

  describe('activeWhen', () => {
    it('does not mount feature when activeWhen returns false', async () => {
      await import('../featureRegistry')

      const mount = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'inactive-feature',
          feature: () => createMockLifecycle({mount}),
          activeWhen: () => false,
        }),
      )

      await window.CANVAS.startFeatures()

      expect(mount).not.toHaveBeenCalled()
    })

    it('mounts feature when activeWhen returns true', async () => {
      await import('../featureRegistry')

      const mount = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'active-feature',
          feature: () => createMockLifecycle({mount}),
          activeWhen: () => true,
        }),
      )

      await window.CANVAS.startFeatures()

      expect(mount).toHaveBeenCalled()
    })
  })

  describe('overrides', () => {
    it('does not mount overridden feature', async () => {
      await import('../featureRegistry')

      const originalMount = vi.fn()
      const overrideMount = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'original-feature',
          feature: () => createMockLifecycle({mount: originalMount}),
        }),
      )
      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'override-feature',
          feature: () => createMockLifecycle({mount: overrideMount}),
          overrides: 'original-feature',
        }),
      )

      await window.CANVAS.startFeatures()

      expect(originalMount).not.toHaveBeenCalled()
      expect(overrideMount).toHaveBeenCalled()
    })

    it('warns when trying to override already mounted feature', async () => {
      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      await import('../featureRegistry')

      const originalMount = vi.fn()

      // Register and start features with just the original
      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'already-mounted',
          feature: () => createMockLifecycle({mount: originalMount}),
        }),
      )

      await window.CANVAS.startFeatures()

      // Now try to register an override after original is mounted
      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'late-override',
          overrides: 'already-mounted',
        }),
      )

      await new Promise(resolve => setTimeout(resolve, 0))

      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('already mounted'))

      consoleSpy.mockRestore()
    })
  })

  describe('slot resolution', () => {
    it('passes container element to mount when slot is found', async () => {
      await import('../featureRegistry')

      const container = document.createElement('div')
      container.id = 'test-slot'
      document.body.appendChild(container)

      const mount = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'slotted-feature',
          feature: () => createMockLifecycle({mount}),
          slot: 'test-slot',
        }),
      )

      await window.CANVAS.startFeatures()

      expect(mount).toHaveBeenCalledWith(container)

      document.body.removeChild(container)
    })

    it('warns and does not mount when slot element not found', async () => {
      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
      await import('../featureRegistry')

      const mount = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'missing-slot-feature',
          feature: () => createMockLifecycle({mount}),
          slot: 'nonexistent-slot',
        }),
      )

      await window.CANVAS.startFeatures()

      expect(mount).not.toHaveBeenCalled()
      expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('not found'))

      consoleSpy.mockRestore()
    })

    it('accepts Element directly as slot', async () => {
      await import('../featureRegistry')

      const container = document.createElement('div')
      const mount = vi.fn()

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'element-slot-feature',
          feature: () => createMockLifecycle({mount}),
          slot: container,
        }),
      )

      await window.CANVAS.startFeatures()

      expect(mount).toHaveBeenCalledWith(container)
    })
  })

  describe('error handling', () => {
    it('catches and logs errors during mount', async () => {
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
      await import('../featureRegistry')

      const error = new Error('Mount failed')

      window.CANVAS.registerFeature(
        createMockConfig({
          name: 'failing-feature',
          feature: () =>
            createMockLifecycle({
              mount: () => {
                throw error
              },
            }),
        }),
      )

      await window.CANVAS.startFeatures()

      expect(consoleSpy).toHaveBeenCalledWith('Failed to mount feature "failing-feature":', error)

      consoleSpy.mockRestore()
    })
  })

  describe('getFeatures and getMounted', () => {
    it('returns copies of internal state', async () => {
      await import('../featureRegistry')

      window.CANVAS.registerFeature(createMockConfig({name: 'copy-test'}))
      await window.CANVAS.startFeatures()

      const features1 = window.CANVAS.getFeatures()
      const features2 = window.CANVAS.getFeatures()

      expect(features1).not.toBe(features2)
      expect(features1).toEqual(features2)

      const mounted1 = window.CANVAS.getMounted()
      const mounted2 = window.CANVAS.getMounted()

      expect(mounted1).not.toBe(mounted2)
      expect(mounted1).toEqual(mounted2)
    })
  })
})
