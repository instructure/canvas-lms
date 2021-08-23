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
import TrophyDisplay from './TrophyDisplay'
import DateDisplay from '../DateDisplay'
import DescriptionDisplay from '../DescriptionDisplay'

export default function Trophy(props) {
  return (
    <Flex direction="column" width={250} alignItems="center" justifyItems="center">
      <Flex.Item>
        <TrophyDisplay {...props} />
      </Flex.Item>
      <Flex.Item shouldGrow>
        <Flex direction="column" textAlign="center">
          <Flex.Item>
            <DescriptionDisplay descriptionSize="medium" {...props} />
          </Flex.Item>
          <Flex.Item>
            <DateDisplay size="small" color="secondary" {...props} />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}
