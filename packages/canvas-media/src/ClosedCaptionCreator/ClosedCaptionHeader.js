/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {Flex} from '@instructure/ui-layout'
import {Text} from '@instructure/ui-elements'

export default function ClosedCaptionHeader({
  CLOSED_CAPTIONS_LANGUAGE_HEADER,
  CLOSED_CAPTIONS_FILE_NAME_HEADER,
  CLOSED_CAPTIONS_ACTIONS_HEADER
}) {
  return (
    <div style={{borderBottom: '1px solid grey'}}>
      <Flex justifyItems="space-between" padding="medium 0 xx-small 0">
        <Flex.Item textAlign="start" size="200px">
          <Text weight="bold">{CLOSED_CAPTIONS_LANGUAGE_HEADER}</Text>
        </Flex.Item>
        <Flex.Item textAlign="start">
          <Text weight="bold">{CLOSED_CAPTIONS_FILE_NAME_HEADER}</Text>
        </Flex.Item>
        <Flex.Item textAlign="end" shrink grow>
          <Text weight="bold">{CLOSED_CAPTIONS_ACTIONS_HEADER}</Text>
        </Flex.Item>
      </Flex>
    </div>
  )
}
