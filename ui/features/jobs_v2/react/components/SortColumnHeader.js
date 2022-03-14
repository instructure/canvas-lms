/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useCallback} from 'react'
import {CondensedButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'

export default function SortColumnHeader({bucket, attr, content, sortColumn, onClickHeader}) {
  const sortIndicator = useCallback(() => {
    // I'm kind of torn on whether to implement sorting in either direction in the API (and UI)
    // since, generally speaking, one way is a lot more useful than the other here
    if (attr === sortColumn) {
      if (
        attr === 'id' ||
        attr === 'count' ||
        attr === 'failed_at' ||
        (attr === 'info' && bucket !== 'future')
      ) {
        return '▼'
      } else {
        return '▲'
      }
    } else {
      return null
    }
  }, [bucket, attr, sortColumn])

  const s = sortIndicator()
  if (s) {
    return (
      <Text>
        {s} {content}
      </Text>
    )
  } else {
    return (
      <CondensedButton
        theme={{primaryGhostColor: 'licorice', fontWeight: 'bold'}}
        onClick={() => onClickHeader(attr)}
      >
        {content}
      </CondensedButton>
    )
  }
}
