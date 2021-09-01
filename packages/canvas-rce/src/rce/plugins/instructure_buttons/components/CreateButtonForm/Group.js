/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {ToggleGroup} from '@instructure/ui-toggle-details'
import formatMessage from '../../../../../format-message'

export function Group({children, summary, ...props}) {
  return (
    <ToggleGroup
      background="default"
      border={false}
      padding="small small 0"
      summary={summary}
      toggleLabel={formatMessage('Toggle {summary} group', {summary})}
      {...props}
    >
      {children}
    </ToggleGroup>
  )
}
