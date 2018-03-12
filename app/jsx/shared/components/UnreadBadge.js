/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import { string, number, oneOfType, node } from 'prop-types'
import Tooltip from '@instructure/ui-core/lib/components/Tooltip'

export default function UnreadBadge ({ unreadCount, totalCount, unreadLabel, totalLabel }) {
  return (
    <span className="ic-unread-badge">
      <Tooltip tip={unreadLabel} variant="inverse">
        <span className="ic-unread-badge__count ic-unread-badge__unread-count">{unreadCount}</span>
      </Tooltip>
      <Tooltip tip={totalLabel} variant="inverse">
        <span className="ic-unread-badge__count ic-unread-badge__total-count">{totalCount}</span>
      </Tooltip>
    </span>
  )
}

UnreadBadge.propTypes = {
  unreadCount: oneOfType([string, number]).isRequired,
  totalCount: oneOfType([string, number]).isRequired,
  unreadLabel: oneOfType([string, node]).isRequired,
  totalLabel: oneOfType([string, node]).isRequired,
}
