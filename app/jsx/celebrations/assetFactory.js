/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

export default function assetFactory(key) {
  switch (key) {
    case 'balloon':
      return require('./assets/Balloon.svg')
    case 'bifrost_trophy':
      return require('./assets/BifrostTrophy.svg')
    case 'butterfly':
      return require('./assets/Butterfly.svg')
    case 'einstein_rosen_trophy':
      return require('./assets/EinsteinRosenTrophy.svg')
    case 'fire':
      return require('./assets/Fire.svg')
    case 'flowers':
      return require('./assets/Flowers.svg')
    case 'four_leaf_clover':
      return require('./assets/FourLeafClover.svg')
    case 'gift':
      return require('./assets/Gift.svg')
    case 'gnome':
      return require('./assets/Gnome.svg')
    case 'helix_rocket':
      return require('./assets/HelixRocket.svg')
    case 'horse_shoe':
      return require('./assets/HorseShoe.svg')
    case 'hot_air_balloon':
      return require('./assets/HotAirBalloon.svg')
    case 'magic_mystery_thumbs_up':
      return require('./assets/MagicMysteryThumbsUp.svg')
    case 'medal':
      return require('./assets/Medal.svg')
    case 'moon':
      return require('./assets/Moon.svg')
    case 'ninja':
      return require('./assets/Ninja.svg')
    case 'panama_rocket':
      return require('./assets/PanamaRocket.svg')
    case 'panda':
      return require('./assets/Panda.svg')
    case 'panda_unicycle':
      return require('./assets/PandaUnicycle.svg')
    case 'pinwheel':
      return require('./assets/Pinwheel.svg')
    case 'pizza_slice':
      return require('./assets/PizzaSlice.svg')
    case 'rocket':
      return require('./assets/Rocket.svg')
    case 'star':
      return require('./assets/Star.svg')
    case 'thumbs_up':
      return require('./assets/ThumbsUp.svg')
    case 'trophy':
      return require('./assets/Trophy.svg')
    default:
      throw new Error(`Unknown asset key: ${key}`)
  }
}
