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
import {Tooltip} from '@instructure/ui-tooltip'
import {Pill} from '@instructure/ui-pill'
import {DiscussionSummaryUsage} from './DiscussionSummary'

const I18n = createI18nScope('discussions_posts')

interface Props extends DiscussionSummaryUsage {}

export const DiscussionSummaryUsagePill: React.FC<Props> = props => {
    const limitNotReachedText = I18n.t('The maximum number of summary generations allowed per user per day is %{limit}.', {limit: props.limit})
    const limitReachedText = I18n.t('Sorry, you have reached the maximum number of summary generations allowed (%{limit}) per day. Please try again tomorrow.', {limit: props.limit})
    const limitReached = props.currentCount >= props.limit
    const tooltipText = limitReached ? limitReachedText : limitNotReachedText
    const color = limitReached ? 'danger' : 'success'

    return (
      <Tooltip renderTip={tooltipText} width="48px" data-testid="summary-generate-tooltip">
          <Pill color={color} margin="x-small" data-testid="summary-usage-pill">
              {props.currentCount} / {props.limit}
          </Pill>
      </Tooltip>
    )
}
