/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {
  IconCertifiedSolid,
  IconEmptySolid,
  IconOvalHalfLine,
  IconClockLine,
  IconWarningLine,
} from '@instructure/ui-icons'

interface SimilarityIconProps {
  similarityScore?: number
  status: 'error' | 'pending' | 'scored'
}

export default function SimilarityIcon({similarityScore, status}: SimilarityIconProps) {
  if (status === 'scored' && similarityScore != null) {
    if (similarityScore <= 20) {
      return <IconCertifiedSolid color="success" data-testid="similarity-icon" />
    } else if (similarityScore <= 60) {
      return <IconOvalHalfLine color="error" data-testid="similarity-icon" />
    } else {
      return <IconEmptySolid color="error" data-testid="similarity-icon" />
    }
  } else if (status === 'pending') {
    return <IconClockLine data-testid="similarity-clock-icon" />
  }

  return <IconWarningLine data-testid="similarity-icon" />
}
