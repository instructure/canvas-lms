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

import React from 'react'
import {Img} from '@instructure/ui-img'

// TODO: figure out the long term strategy for rendering assets.
// for now, just grab a few from confetti
const assetFor = key => {
  switch (key) {
    case 'Ninja':
      return require('../../confetti/svg/Ninja.svg')
    case 'FourLeafClover':
      return require('../../confetti/svg/FourLeafClover.svg')
    default:
      return require('../../confetti/svg/Trophy.svg')
  }
}

export default function ImageDisplay(props) {
  const options = !props.unlocked_at
    ? {
        withGrayscale: true,
        withBlur: true
      }
    : {}
  return (
    // TODO: better alt text once we know what backend data looks like
    <Img
      alt={props.trophy_key}
      height={props.height || 70}
      width={props.width || 70}
      src={assetFor(props.trophy_key)}
      margin="x-small small"
      {...options}
    />
  )
}
