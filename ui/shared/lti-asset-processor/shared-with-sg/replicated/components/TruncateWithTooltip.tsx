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

// Directly copied from canvas-lms's ui/shared/lti-apps/components/common/TruncateWithTooltip.tsx
// Yes, this is duplicated now, in the interest of isolating LtiAssetReports code for shared use with Canvas

import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import type React from 'react'
import {useState} from 'react'

interface TruncateWithTooltipProps {
  children: React.ReactNode
  linesAllowed: number
  horizontalOffset: number
  backgroundColor: 'primary' | 'primary-inverse' | undefined
}

const TruncateWithTooltip = (props: TruncateWithTooltipProps): JSX.Element => {
  const {children, linesAllowed, horizontalOffset, backgroundColor} = props
  const [isTruncated, setIsTruncated] = useState(false)

  return isTruncated ? (
    <Tooltip
      as="div"
      placement="top"
      color={backgroundColor}
      offsetX={horizontalOffset}
      renderTip={children}
    >
      <TruncateText
        maxLines={linesAllowed}
        ignore={[' ', '.', ',']}
        ellipsis=" ..."
        onUpdate={setIsTruncated}
      >
        {children}
      </TruncateText>
    </Tooltip>
  ) : (
    <TruncateText maxLines={linesAllowed} onUpdate={setIsTruncated}>
      {children}
    </TruncateText>
  )
}

export default TruncateWithTooltip
