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

export interface FeatureLifecycle {
  bootstrap?: () => Promise<void> | void
  mount: (container?: Element) => Promise<void> | void
  unmount?: () => Promise<void> | void
}

/**
 * Configuration for registering a feature with the registry.
 *
 * @example
 * ```ts
 * window.CANVAS.registerFeature({
 *   name: 'my-feature',
 *   feature: () => import('./MyFeature').then(m => m.lifecycle),
 *   slot: 'my-feature-container',
 *   activeWhen: () => window.ENV.current_user_id != null,
 * })
 * ```
 */
export interface FeatureConfig {
  name: string
  feature: () => Promise<FeatureLifecycle> | FeatureLifecycle
  slot?: string | Element | null
  activeWhen?: () => boolean
  overrides?: string
}

interface InternalFeature {
  config: FeatureConfig
  lifecycle?: FeatureLifecycle
  bootstrapped: boolean
}

class FeatureRegistry {
  private _features: Map<string, InternalFeature> = new Map()
  private _mounted: Set<string> = new Set()
  private _started: boolean = false

  registerFeature(config: FeatureConfig): void {
    if (this._features.has(config.name)) {
      console.error(`Feature "${config.name}" already registered, ignoring duplicate`)
      return
    }

    this._features.set(config.name, {
      config,
      bootstrapped: false,
    })

    if (this._started) {
      // Don't block registration, but do mount async
      this._mountFeature(config.name)
    }
  }

  async startFeatures(): Promise<void> {
    this._started = true

    const overrides = new Map<string, string>()
    this._features.forEach((feature, _name) => {
      if (feature.config.overrides) {
        overrides.set(feature.config.overrides, feature.config.name)
      }
    })

    const featureNames = Array.from(this._features.keys())
    for (let i = 0; i < featureNames.length; i++) {
      const name = featureNames[i]
      if (overrides.has(name)) {
        continue
      }

      await this._mountFeature(name)
    }
  }

  getFeatures(): Map<string, InternalFeature> {
    return new Map(this._features)
  }

  getMounted(): Set<string> {
    return new Set(this._mounted)
  }

  private async _mountFeature(name: string): Promise<void> {
    const feature = this._features.get(name)
    if (!feature) return

    const {config} = feature

    if (config.activeWhen && !config.activeWhen()) {
      return
    }

    if (config.overrides && this._mounted.has(config.overrides)) {
      console.warn(
        `Feature "${name}" wants to override "${config.overrides}" ` +
          `but it's already mounted. Override ignored.`,
      )
      return
    }

    try {
      const lifecycle = await Promise.resolve(config.feature())
      feature.lifecycle = lifecycle

      if (!feature.bootstrapped && lifecycle.bootstrap) {
        await Promise.resolve(lifecycle.bootstrap())
        feature.bootstrapped = true
      }

      let container: Element | undefined
      if (config.slot) {
        if (typeof config.slot === 'string') {
          container = document.getElementById(config.slot) ?? undefined
        } else if (config.slot instanceof Element) {
          container = config.slot
        }

        if (!container) {
          console.warn(`Slot "${config.slot}" not found for feature "${name}"`)
          return
        }
      }

      await Promise.resolve(lifecycle.mount(container))
      this._mounted.add(name)
    } catch (error) {
      console.error(`Failed to mount feature "${name}":`, error)
    }
  }
}

const registry = new FeatureRegistry()

export interface CanvasFeatureRegistryMethods {
  registerFeature: (config: FeatureConfig) => void
  startFeatures: () => Promise<void>
  getFeatures: () => Map<string, InternalFeature>
  getMounted: () => Set<string>
}

declare global {
  interface Window {
    CANVAS: {
      registerFeature: (config: FeatureConfig) => void
      startFeatures: () => Promise<void>
      getFeatures: () => Map<string, InternalFeature>
      getMounted: () => Set<string>
    }
  }
}

window.CANVAS = window.CANVAS || ({} as Window['CANVAS'])
window.CANVAS.registerFeature = (config: FeatureConfig) => registry.registerFeature(config)
window.CANVAS.startFeatures = () => registry.startFeatures()
window.CANVAS.getFeatures = () => registry.getFeatures()
window.CANVAS.getMounted = () => registry.getMounted()
