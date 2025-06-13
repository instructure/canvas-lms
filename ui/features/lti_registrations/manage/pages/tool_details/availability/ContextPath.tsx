/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import * as React from 'react'
import {Flex} from '@instructure/ui-flex'

export type ContextPathProps = {
  path: string[]
}

export const ContextPath = ({path}: ContextPathProps) => {
  let beginningPathSegments: string[] = []
  let lastPathSegment: string | undefined = undefined

  if (path.length === 1) {
    beginningPathSegments = path
    lastPathSegment = undefined
  } else if (path.length > 1) {
    beginningPathSegments = path.slice(0, -1)
    lastPathSegment = path[path.length - 1]
  }

  return (
    <Flex alignItems="center">
      <div
        style={{
          flexShrink: 1,
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
        }}
      >
        {beginningPathSegments.join(' / ')}
      </div>
      {lastPathSegment && (
        <Flex.Item margin="0 0 0 xx-small">
          {' / '}
          {lastPathSegment}
        </Flex.Item>
      )}
    </Flex>
  )
}
