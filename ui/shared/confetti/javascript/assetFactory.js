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

import balloon from '../images/Balloon.svg'
import bifrost_trophy from '../images/BifrostTrophy.svg'
import butterfly from '../images/Butterfly.svg'
import einstein_rosen_trophy from '../images/EinsteinRosenTrophy.svg'
import fire from '../images/Fire.svg'
import flowers from '../images/Flowers.svg'
import four_leaf_clover from '../images/FourLeafClover.svg'
import gift from '../images/Gift.svg'
import gnome from '../images/Gnome.svg'
import helix_rocket from '../images/HelixRocket.svg'
import horse_shoe from '../images/HorseShoe.svg'
import hot_air_balloon from '../images/HotAirBalloon.svg'
import magic_mystery_thumbs_up from '../images/MagicMysteryThumbsUp.svg'
import medal from '../images/Medal.svg'
import moon from '../images/Moon.svg'
import ninja from '../images/Ninja.svg'
import panama_rocket from '../images/PanamaRocket.svg'
import panda from '../images/Panda.svg'
import panda_unicycle from '../images/PandaUnicycle.svg'
import pinwheel from '../images/Pinwheel.svg'
import pizza_slice from '../images/PizzaSlice.svg'
import rocket from '../images/Rocket.svg'
import star from '../images/Star.svg'
import thumbs_up from '../images/ThumbsUp.svg'
import trophy from '../images/Trophy.svg'

export default function assetFactory(key) {
  switch (key) {
    case 'balloon':
      return balloon
    case 'bifrost_trophy':
      return bifrost_trophy
    case 'butterfly':
      return butterfly
    case 'einstein_rosen_trophy':
      return einstein_rosen_trophy
    case 'fire':
      return fire
    case 'flowers':
      return flowers
    case 'four_leaf_clover':
      return four_leaf_clover
    case 'gift':
      return gift
    case 'gnome':
      return gnome
    case 'helix_rocket':
      return helix_rocket
    case 'horse_shoe':
      return horse_shoe
    case 'hot_air_balloon':
      return hot_air_balloon
    case 'magic_mystery_thumbs_up':
      return magic_mystery_thumbs_up
    case 'medal':
      return medal
    case 'moon':
      return moon
    case 'ninja':
      return ninja
    case 'panama_rocket':
      return panama_rocket
    case 'panda':
      return panda
    case 'panda_unicycle':
      return panda_unicycle
    case 'pinwheel':
      return pinwheel
    case 'pizza_slice':
      return pizza_slice
    case 'rocket':
      return rocket
    case 'star':
      return star
    case 'thumbs_up':
      return thumbs_up
    case 'trophy':
      return trophy
    default:
      throw new Error(`Unknown asset key: ${key}`)
  }
}
