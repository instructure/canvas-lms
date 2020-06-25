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
import {Flex} from '@instructure/ui-flex'
import cx from 'classnames'

// TODO: figure out the long term strategy for rendering assets.
// for now, just grab a few from confetti
const assetFor = key => {
  switch (key) {
    case 'Ninja':
      return require('../../../confetti/svg/Ninja.svg')
    case 'FourLeafClover':
      return require('../../../confetti/svg/FourLeafClover.svg')
    default:
      return require('../../../confetti/svg/Trophy.svg')
  }
}

export default function TrophyDisplay(props) {
  const options = !props.unlocked_at
    ? {
        withGrayscale: true,
        withBlur: true
      }
    : {}
  const containerClass = cx('image-container', {
    'image-container__unlocked': props.unlocked_at,
    'image-container__locked': !props.unlocked_at
  })
  return (
    <div className={containerClass}>
      <Flex alignItems="center" justifyItems="center">
        <Flex.Item>
          <Img
            alt={props.trophy_key}
            height={90}
            width={90}
            src={assetFor(props.trophy_key)}
            {...options}
          />
        </Flex.Item>
      </Flex>
    </div>
  )
}
