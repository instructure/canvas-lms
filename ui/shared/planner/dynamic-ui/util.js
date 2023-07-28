/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {srAlert} from '../utilities/alertUtils'

const I18n = useI18nScope('planner')

export function specialFallbackFocusId(type) {
  return `~~~${type}-fallback-focus~~~`
}

export function handleNothingToday(manager, todayElem, focusTarget) {
  if (!focusTarget) {
    srAlert(I18n.t('There is nothing planned for today.'))
  }

  // In the weekly planner the missing assignments will be under Today
  // if there are any.
  const missingAssignments = manager.getDocument().getElementById('MissingAssignments')
  if (focusTarget === 'missing-items' && missingAssignments) {
    manager.getAnimator().focusElement(missingAssignments)
  }

  if (todayElem) {
    manager.getAnimator().forceScrollTo(todayElem, manager.totalOffset())
  } else {
    manager.getAnimator().scrollToTop()
  }
}
