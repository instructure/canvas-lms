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

import React, {useMemo} from 'react'
import {View} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CompletionRequirement} from '../utils/types'
import {IconShapeOvalLine} from '@instructure/ui-icons'

const I18n = createI18nScope('context_modules_v2')

interface InProgressModuleItemStatusProps {
  completionRequirement: CompletionRequirement
}
export const InProgressModuleItemStatus: React.FC<InProgressModuleItemStatusProps> = (
  props: InProgressModuleItemStatusProps,
) => {
  const {completionRequirement} = props

  const itemTypeText = useMemo(() => {
    switch (completionRequirement.type) {
      case 'must_view':
        return I18n.t('Must view the page')
      case 'must_mark_done':
        return I18n.t('Must mark as done')
      case 'must_submit':
        return I18n.t('Must submit the assignment')
      case 'min_score':
        return I18n.t('Must score at least a %{score}', {score: completionRequirement.minScore})
      case 'min_percentage':
        return I18n.t('Must score at least a %{percentage}', {
          percentage: completionRequirement.minPercentage,
        })
      case 'must_contribute':
        return I18n.t('Must contribute to the page')
      default:
        return I18n.t('Not yet completed')
    }
  }, [
    completionRequirement.type,
    completionRequirement.minScore,
    completionRequirement.minPercentage,
  ])

  return (
    <Tooltip
      renderTip={
        <View display="block" id="alt-text-label-tooltip" maxWidth="14rem">
          {itemTypeText}
        </View>
      }
      placement="top"
    >
      <IconShapeOvalLine data-testid="assigned-icon" />
    </Tooltip>
  )
}
