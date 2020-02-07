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
import giftUrl from '../svg/Gift.svg'

const confettiFlavors = [
  'circle',
  'square',
  'triangle',
  'line',
  {type: 'svg', src: giftUrl, weight: 0.1, size: 20}
]

/**
 * Returns a random element to be added to the confetti. New assets
 * should be added to the svg directory, then added to the list of
 * potential flavors.
 */
export default function getRandomConfettiFlavor() {
  return sample(confettiFlavors)
}
