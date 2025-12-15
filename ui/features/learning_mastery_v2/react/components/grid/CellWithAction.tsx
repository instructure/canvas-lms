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
import React from 'react'
import {FocusableCell, FocusableCellProps} from './FocusableCell'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconExpandStartLine} from '@instructure/ui-icons'

export interface CellWithActionProps extends Omit<FocusableCellProps, 'children'> {
  children: React.ReactNode
  actionLabel: string
  onAction?: () => void
}

export const CellWithAction: React.FC<CellWithActionProps> = ({
  children,
  actionLabel,
  onAction,
  ...props
}) => {
  return (
    <FocusableCell {...props}>
      {focused => (
        <Flex height="100%">
          {children}
          {focused && (
            <IconButton
              withBackground={false}
              withBorder={false}
              size="small"
              margin="small"
              renderIcon={<IconExpandStartLine />}
              screenReaderLabel={actionLabel}
              onClick={onAction}
              disabled={!onAction}
            />
          )}
        </Flex>
      )}
    </FocusableCell>
  )
}
