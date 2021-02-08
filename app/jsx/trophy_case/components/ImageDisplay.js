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
import assetFactory from 'jsx/celebrations/assetFactory'

// TODO: still defaults to trophy, figure out long term
// error handling here
const getAsset = key => {
  try {
    return assetFactory(key)
  } catch (e) {
    return assetFactory('trophy')
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
      src={getAsset(props.trophy_key)}
      margin="x-small small"
      {...options}
    />
  )
}
