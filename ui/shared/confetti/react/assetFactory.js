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
      return require('../images/Balloon.svg')
    case 'bifrost_trophy':
      return require('../images/BifrostTrophy.svg')
    case 'butterfly':
      return require('../images/Butterfly.svg')
    case 'einstein_rosen_trophy':
      return require('../images/EinsteinRosenTrophy.svg')
    case 'fire':
      return require('../images/Fire.svg')
    case 'flowers':
      return require('../images/Flowers.svg')
    case 'four_leaf_clover':
      return require('../images/FourLeafClover.svg')
    case 'gift':
      return require('../images/Gift.svg')
    case 'gnome':
      return require('../images/Gnome.svg')
    case 'helix_rocket':
      return require('../images/HelixRocket.svg')
    case 'horse_shoe':
      return require('../images/HorseShoe.svg')
    case 'hot_air_balloon':
      return require('../images/HotAirBalloon.svg')
    case 'magic_mystery_thumbs_up':
      return require('../images/MagicMysteryThumbsUp.svg')
    case 'medal':
      return require('../images/Medal.svg')
    case 'moon':
      return require('../images/Moon.svg')
    case 'ninja':
      return require('../images/Ninja.svg')
    case 'panama_rocket':
      return require('../images/PanamaRocket.svg')
    case 'panda':
      return require('../images/Panda.svg')
    case 'panda_unicycle':
      return require('../images/PandaUnicycle.svg')
    case 'pinwheel':
      return require('../images/Pinwheel.svg')
    case 'pizza_slice':
      return require('../images/PizzaSlice.svg')
    case 'rocket':
      return require('../images/Rocket.svg')
    case 'star':
      return require('../images/Star.svg')
    case 'thumbs_up':
      return require('../images/ThumbsUp.svg')
    case 'trophy':
      return require('../images/Trophy.svg')
    default:
      throw new Error(`Unknown asset key: ${key}`)
  }
}
