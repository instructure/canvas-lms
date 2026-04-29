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

import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {IconArrowOpenEndLine} from '@instructure/ui-icons'

const I18n = createI18nScope('EditMasteryScaleLink')

export interface EditMasteryScaleLinkProps {
  outcome: Outcome
  accountLevelMasteryScalesFF: boolean
  masteryScaleContextType?: string
  masteryScaleContextId?: string
}

export const EditMasteryScaleLink: React.FC<EditMasteryScaleLinkProps> = ({
  outcome,
  accountLevelMasteryScalesFF,
  masteryScaleContextType,
  masteryScaleContextId,
}) => {
  const editMasteryScaleUrl = useMemo(() => {
    const contextType = masteryScaleContextType
    const contextId = masteryScaleContextId

    if (!contextType || !contextId) return null

    const baseUrl = `/${contextType.toLowerCase()}s/${contextId}/outcomes`

    // FF ON: Add #mastery_scale hash (opens Mastery tab)
    if (accountLevelMasteryScalesFF) {
      return `${baseUrl}#mastery_scale`
    }

    // Include group_id if available for more efficient navigation
    const params = new URLSearchParams({outcome_id: outcome.id.toString()})
    if (outcome.group_id) {
      params.set('group_id', outcome.group_id)
    }
    return `${baseUrl}?${params.toString()}`
  }, [
    accountLevelMasteryScalesFF,
    masteryScaleContextType,
    masteryScaleContextId,
    outcome.id,
    outcome.group_id,
  ])

  if (!editMasteryScaleUrl) {
    return null
  }

  return (
    <Link
      href={editMasteryScaleUrl}
      data-testid="configure-mastery-link"
      target="_blank"
      rel="noopener noreferrer"
      renderIcon={<IconArrowOpenEndLine size="x-small" />}
      iconPlacement="end"
    >
      <Text size="small">{I18n.t('Configure Mastery')}</Text>
    </Link>
  )
}
