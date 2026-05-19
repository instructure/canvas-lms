/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {IconCheckSolid} from '@instructure/ui-icons'
import {colors} from '@instructure/canvas-theme'

const BADGE_SIZE = 16

export function SelectedBadge() {
  return (
    <span
      style={{
        position: 'absolute',
        bottom: -2,
        right: -2,
        width: BADGE_SIZE,
        height: BADGE_SIZE,
        borderRadius: '50%',
        backgroundColor: colors.dataVisualization.forest45Primary,
        border: `1px solid ${colors.primitives.white}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        pointerEvents: 'none',
      }}
    >
      <IconCheckSolid width={10} height={10} color="primary-inverse" />
    </span>
  )
}
