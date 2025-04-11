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

import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

interface UpdatedAtDateProps {
  updatedAt: string
  isStacked: boolean
}

export const UpdatedAtDate = ({updatedAt, isStacked}: UpdatedAtDateProps) => {
  if (isStacked) {
    return <FriendlyDatetime dateTime={updatedAt} includeScreenReaderContent={false}/>
  } else {
    return (
      <div style={{padding: '0 0.5em'}}>
        <FriendlyDatetime dateTime={updatedAt} includeScreenReaderContent={false}/>
      </div>
    )
  }
}
