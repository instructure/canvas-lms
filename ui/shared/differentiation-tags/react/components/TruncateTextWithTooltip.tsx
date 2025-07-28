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

import {TruncateText} from '@instructure/ui-truncate-text'
import {Tooltip} from '@instructure/ui-tooltip'
import React, {useState, useEffect} from 'react'

const TruncateTextWithTooltip = ({children}: {children: React.ReactNode}) => {
  const [isTruncated, setIsTruncated] = useState(false)

  useEffect(() => {
    setIsTruncated(false)
  }, [children])

  const content = <TruncateText onUpdate={setIsTruncated}>{children}</TruncateText>

  return isTruncated ? (
    <Tooltip as="div" renderTip={() => children} data-testid="tooltip-container">
      {content}
    </Tooltip>
  ) : (
    content
  )
}

export default TruncateTextWithTooltip
