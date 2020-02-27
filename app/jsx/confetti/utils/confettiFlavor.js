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

import {sample} from 'lodash'
import balloonUrl from '../svg/Balloon.svg'
import bifrostTrophyUrl from '../svg/BifrostTrophy.svg'
import butterflyUrl from '../svg/Butterfly.svg'
import einsteinRosenTrophyUrl from '../svg/EinsteinRosenTrophy.svg'
import fireUrl from '../svg/Fire.svg'
import flowersUrl from '../svg/Flowers.svg'
import fourLeafCloverUrl from '../svg/FourLeafClover.svg'
import giftUrl from '../svg/Gift.svg'
import gnomeUrl from '../svg/Gnome.svg'
import helixRocketUrl from '../svg/HelixRocket.svg'
import horseshoeUrl from '../svg/Horseshoe.svg'
import hotairBalloonUrl from '../svg/HotairBalloon.svg'
import magicMysteryThumbsUpUrl from '../svg/MagicMysteryThumbsUp.svg'
import medalUrl from '../svg/Medal.svg'
import moonUrl from '../svg/Moon.svg'
import ninjaUrl from '../svg/Ninja.svg'
import panamaRocketUrl from '../svg/PanamaRocket.svg'
import pandaUrl from '../svg/Panda.svg'
import pinwheelUrl from '../svg/Pinwheel.svg'
import pizzaSliceUrl from '../svg/PizzaSlice.svg'
import rocketUrl from '../svg/Rocket.svg'
import starUrl from '../svg/Star.svg'
import thumbsUpUrl from '../svg/ThumbsUp.svg'
import trophyUrl from '../svg/Trophy.svg'

const confettiFlavors = [
  'circle',
  'square',
  'triangle',
  'line',
  {type: 'svg', src: balloonUrl, weight: 0.05, size: 40},
  {type: 'svg', src: bifrostTrophyUrl, weight: 0.05, size: 40},
  {type: 'svg', src: butterflyUrl, weight: 0.05, size: 40},
  {type: 'svg', src: einsteinRosenTrophyUrl, weight: 0.05, size: 40},
  {type: 'svg', src: fireUrl, weight: 0.05, size: 40},
  {type: 'svg', src: flowersUrl, weight: 0.05, size: 40},
  {type: 'svg', src: fourLeafCloverUrl, weight: 0.05, size: 40},
  {type: 'svg', src: giftUrl, weight: 0.05, size: 40},
  {type: 'svg', src: gnomeUrl, weight: 0.05, size: 40},
  {type: 'svg', src: helixRocketUrl, weight: 0.05, size: 40},
  {type: 'svg', src: horseshoeUrl, weight: 0.05, size: 40},
  {type: 'svg', src: hotairBalloonUrl, weight: 0.05, size: 40},
  {type: 'svg', src: magicMysteryThumbsUpUrl, weight: 0.05, size: 40},
  {type: 'svg', src: medalUrl, weight: 0.05, size: 40},
  {type: 'svg', src: moonUrl, weight: 0.05, size: 40},
  {type: 'svg', src: ninjaUrl, weight: 0.05, size: 40},
  {type: 'svg', src: panamaRocketUrl, weight: 0.05, size: 40},
  {type: 'svg', src: pandaUrl, weight: 0.05, size: 40},
  {type: 'svg', src: pinwheelUrl, weight: 0.05, size: 40},
  {type: 'svg', src: pizzaSliceUrl, weight: 0.05, size: 40},
  {type: 'svg', src: rocketUrl, weight: 0.05, size: 40},
  {type: 'svg', src: starUrl, weight: 0.05, size: 40},
  {type: 'svg', src: thumbsUpUrl, weight: 0.05, size: 40},
  {type: 'svg', src: trophyUrl, weight: 0.05, size: 40}
]

/**
 * Returns a random element to be added to the confetti. New assets
 * should be added to the svg directory, then added to the list of
 * potential flavors.
 */
export default function getRandomConfettiFlavor() {
  return sample(confettiFlavors)
}
