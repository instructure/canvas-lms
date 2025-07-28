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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {IconAiColoredSolid} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

interface DiscussionInsightsButtonProps {
  isMobile: boolean
  onClick: () => void
}

const I18n = createI18nScope('discussions_posts')

export const DiscussionInsightsButton: React.FC<DiscussionInsightsButtonProps> = props => {
  const buttonText = I18n.t('Go to Insights')
  return (
    <Tooltip renderTip={buttonText} width="48px" data-testid="discussionInsightsButtonTooltip">
      <Button
        onClick={props.onClick}
        color="ai-secondary"
        renderIcon={<IconAiColoredSolid />}
        id="discussion-insights-button"
        data-testid="discussion-insights-button"
        display={props.isMobile ? 'block' : 'inline-block'}
      >
        {buttonText}
      </Button>
    </Tooltip>
  )
}
