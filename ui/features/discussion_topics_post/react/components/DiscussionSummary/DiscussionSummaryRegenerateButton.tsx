/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {Button} from '@instructure/ui-buttons'
import {IconSyllabusLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

interface DiscussionSummaryRegenerateButtonProps {
  onClick: () => void
  isEnabled: boolean
  buttonText: string
}

export const DiscussionSummaryRegenerateButton: React.FC<
  DiscussionSummaryRegenerateButtonProps
> = props => {
  return (
    <Tooltip renderTip={props.buttonText} width="48px" data-testid="summary-regenerate-tooltip">
      <Button
        onClick={props.onClick}
        renderIcon={IconSyllabusLine}
        data-testid="summary-regenerate-button"
        disabled={!props.isEnabled}
      >
        {props.buttonText}
      </Button>
    </Tooltip>
  )
}
