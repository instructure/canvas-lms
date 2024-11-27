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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconSyllabusLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

interface DiscussionSummaryGenerateButtonProps {
  onClick: () => void
  isEnabled: boolean
  isMobile: boolean
}

const I18n = useI18nScope('discussions_posts')

export const DiscussionSummaryGenerateButton: React.FC<
  DiscussionSummaryGenerateButtonProps
> = props => {
  const buttonText = I18n.t('Generate Summary')

  return (
    <Tooltip renderTip={buttonText} width="48px" data-testid="summary-generate-tooltip">
      <Button
        display={props.isMobile ? 'block' : 'inline-block'}
        onClick={props.onClick}
        // @ts-expect-error
        renderIcon={IconSyllabusLine}
        data-testid="summary-generate-button"
        disabled={!props.isEnabled}
      >
        {buttonText}
      </Button>
    </Tooltip>
  )
}
