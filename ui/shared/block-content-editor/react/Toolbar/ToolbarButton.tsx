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

import {ComponentProps} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {colors} from '@instructure/canvas-theme'

export const ToolbarButton = (props: ComponentProps<typeof IconButton>) => {
  return (
    <IconButton
      {...props}
      elementRef={el => {
        if (!el) {
          return
        }

        // Ensure outline is not hidden behind neighboring buttons
        const button = el as HTMLButtonElement
        button.onfocus = () => {
          button.style.zIndex = '10'
        }
        button.onblur = () => {
          button.style.zIndex = 'unset'
        }
      }}
      themeOverride={{
        borderRadius: '0px',
        secondaryBackground: colors.primitives.white,
        secondaryGhostBorderColor: colors.ui.lineStroke,
      }}
    />
  )
}
