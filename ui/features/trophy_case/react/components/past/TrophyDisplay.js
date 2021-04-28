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
import {Flex} from '@instructure/ui-flex'
import cx from 'classnames'
import ImageDisplay from '../ImageDisplay'

export default function TrophyDisplay(props) {
  const containerClass = cx('image-container', {
    'image-container__unlocked': props.unlocked_at,
    'image-container__locked': !props.unlocked_at
  })
  return (
    <div className={containerClass}>
      <Flex alignItems="center" justifyItems="center">
        <Flex.Item>
          <ImageDisplay height={90} width={90} {...props} />
        </Flex.Item>
      </Flex>
    </div>
  )
}
