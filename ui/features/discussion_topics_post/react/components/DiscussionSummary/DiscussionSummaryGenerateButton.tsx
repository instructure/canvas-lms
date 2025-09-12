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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {DiscussionSummaryUsage} from './DiscussionSummary'
import {IconAiSolid} from '@instructure/ui-icons'

interface DiscussionSummaryGenerateButtonProps {
  onClick: () => void
  isEnabled: boolean
  isMobile: boolean
  usage: DiscussionSummaryUsage | null
}

const I18n = createI18nScope('discussions_posts')

export const DiscussionSummaryGenerateButton: React.FC<
  DiscussionSummaryGenerateButtonProps
> = props => {
  const buttonText = I18n.t('Summarize')

  return (
    <Button
      display={props.isMobile ? 'block' : 'inline-block'}
      onClick={props.onClick}
      color="ai-primary"
      renderIcon={<IconAiSolid />}
      data-testid="summary-generate-button"
      disabled={!props.isEnabled}
      aria-label={I18n.t('Ignite AI Summarize')}
    >
      {buttonText}
    </Button>
  )
}
