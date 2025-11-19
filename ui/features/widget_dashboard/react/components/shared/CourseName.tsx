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

import React, {useState} from 'react'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export interface CourseNameProps {
  courseName: string
  maxLines?: number
}

export const CourseName: React.FC<CourseNameProps> = ({courseName, maxLines = 2}) => {
  const [isTruncated, setIsTruncated] = useState(false)

  const textElement = (
    <Text size="medium" weight="bold" lineHeight="condensed">
      {isTruncated && <ScreenReaderContent>{courseName}</ScreenReaderContent>}
      <span aria-hidden={isTruncated} style={{display: 'block'}}>
        <TruncateText maxLines={maxLines} onUpdate={setIsTruncated}>
          {courseName}
        </TruncateText>
      </span>
    </Text>
  )

  if (isTruncated) {
    return (
      <Tooltip
        renderTip={
          <div style={{maxWidth: '300px', wordWrap: 'break-word', whiteSpace: 'normal'}}>
            {courseName}
          </div>
        }
        placement="top"
      >
        {/* eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex */}
        <span tabIndex={0} style={{display: 'block'}}>
          {textElement}
        </span>
      </Tooltip>
    )
  }

  return textElement
}

export default CourseName
