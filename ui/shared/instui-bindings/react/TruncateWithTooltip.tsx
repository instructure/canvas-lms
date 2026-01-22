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

import {useState} from 'react'
import {TruncateText, type TruncateTextProps} from '@instructure/ui-truncate-text'
import {Tooltip, type TooltipProps} from '@instructure/ui-tooltip'

interface TruncateWithTooltipProps {
  children: React.ReactNode
  placement?: TooltipProps['placement']
  /**
   * Allows you to constrain the max width of the tooltip to prevent it from
   * running off the screen.
   */
  maxTooltipWidth?: string | number
  truncate?: TruncateTextProps['truncate']
  position?: TruncateTextProps['position']
  linesAllowed?: number
  horizontalOffset?: number
  backgroundColor?: 'primary' | 'primary-inverse'
}

/**
 * Renders text that will truncate after a certain number of lines
 * and show a tooltip with the full text on hover if truncated.
 * There are a few versions of this in Canvas. However, this one is meant to be re-usable
 * everywhere.
 */
const TruncateWithTooltip = ({
  children,
  placement = 'top',
  maxTooltipWidth: maxWidth = '20rem',
  linesAllowed,
  horizontalOffset,
  backgroundColor,
}: TruncateWithTooltipProps) => {
  const [isTruncated, setIsTruncated] = useState(false)

  const handleUpdate = (truncated: boolean) => {
    if (truncated !== isTruncated) {
      setIsTruncated(truncated)
    }
  }

  return isTruncated ? (
    <Tooltip
      as="div"
      placement={placement}
      color={backgroundColor}
      offsetX={horizontalOffset}
      renderTip={() => <div style={{overflowWrap: 'break-word', maxWidth}}>{children}</div>}
    >
      <TruncateText
        maxLines={linesAllowed}
        ignore={[' ', '.', ',']}
        ellipsis=" ..."
        onUpdate={handleUpdate}
      >
        {children}
      </TruncateText>
    </Tooltip>
  ) : (
    <TruncateText maxLines={linesAllowed} onUpdate={handleUpdate}>
      {children}
    </TruncateText>
  )
}

export default TruncateWithTooltip
