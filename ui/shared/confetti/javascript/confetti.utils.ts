/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import hex2Rgb from '@canvas/util/hex2rgb'
import assetFactory from './assetFactory'
import {sample} from 'lodash'
import type {ConfettiObject, Particle} from '../types'

const confettiFlavors = [
  'balloon',
  'bifrost_trophy',
  'butterfly',
  'einstein_rosen_trophy',
  'fire',
  'flowers',
  'four_leaf_clover',
  'gift',
  'gnome',
  'helix_rocket',
  'horse_shoe',
  'hot_air_balloon',
  'magic_mystery_thumbs_up',
  'medal',
  'moon',
  'ninja',
  'panama_rocket',
  'panda',
  'panda_unicycle',
  'pinwheel',
  'pizza_slice',
  'rocket',
  'star',
  'thumbs_up',
  'trophy',
]

export function getRandomInt(limit: number, floor = false): number {
  if (!limit) limit = 1
  const rand = Math.random() * limit
  return !floor ? rand : Math.floor(rand)
}

export function getWeightedPropIndex(
  props: (string | ConfettiObject)[],
  totalWeight: number
): number {
  let rand = Math.random() * totalWeight
  for (const i in props) {
    const prop = props[i]
    if (typeof prop === 'object' && prop.weight) {
      const weight = prop.weight
      if (rand < weight) return parseInt(i, 10)
      rand -= weight
    } else {
      if (rand < 1) return parseInt(i, 10)
      rand--
    }
  }
  return 0
}

export function generateParticle(
  props: (string | ConfettiObject)[],
  colors: number[][],
  speed: number
): Particle {
  const totalWeight = props.reduce(
    (weight, prop) => weight + (typeof prop === 'string' ? 1 : prop.weight || 1),
    0
  )
  const prop = props[getWeightedPropIndex(props, totalWeight)]
  return {
    prop: typeof prop === 'string' ? prop : prop.type || '',
    x: getRandomInt(window.innerWidth),
    y: getRandomInt(window.innerHeight),
    src: typeof prop === 'object' ? prop.src : undefined,
    size: typeof prop === 'object' ? prop.size : undefined,
    color: colors[getRandomInt(colors.length, true)],
    rotation: (getRandomInt(360, true) * Math.PI) / 180,
    speed: getRandomInt(speed / 7) + speed / 30,
  }
}

export const getBrandingColors = (): number[][] | null => {
  if (window.ENV.confetti_branding_enabled && window.ENV.active_brand_config) {
    const colorVars = window.ENV.active_brand_config.variables
    const primaryBrand = colorVars['ic-brand-primary']
    const secondaryBrand = colorVars['ic-brand-global-nav-bgd']
    const colors = []
    if (primaryBrand) colors.push(Object.values(hex2Rgb(primaryBrand) || {}))
    if (secondaryBrand) colors.push(Object.values(hex2Rgb(secondaryBrand) || {}))
    if (colors.length > 0) {
      return colors
    }
  }
  return null
}

export const getProps = () => {
  const props = ['square', getRandomConfettiFlavor() as ConfettiObject].filter(p => p)
  if (window.ENV.confetti_branding_enabled && window.ENV.active_brand_config) {
    const variables = window.ENV.active_brand_config.variables
    const logoUrl = variables['ic-brand-header-image']
    if (logoUrl) {
      props.push({
        key: 'logo',
        type: 'image',
        src: logoUrl,
        weight: 0.05,
        size: 40,
      })
    }
  }
  return props.filter(p => p !== null)
}

/**
 * Returns a random element to be added to the confetti. New assets
 * should be added to the celebrations directory, then added to the list of
 * potential flavors.
 */
export function getRandomConfettiFlavor() {
  try {
    const flavor = sample(confettiFlavors) || 'balloon'
    return generateConfettiObject(flavor)
  } catch (e) {
    if (e instanceof Error) {
      // eslint-disable-next-line no-console
      console.error(e.stack)
    }
    return null
  }
}

export function generateConfettiObject(key: string) {
  return {
    key,
    type: 'svg',
    src: assetFactory(key),
    weight: 0.05,
    size: 40,
  }
}
