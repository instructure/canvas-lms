/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import Animation from '../animation'
import formatMessage from '../../format-message'
import {srAlert} from '../../utilities/alertUtils'
import {getFriendlyDate} from '../../utilities/dateUtils'
import {assignmentType} from '../../utilities/contentUtils'
import {handleNothingToday} from '../util'

export class FocusFirstItemOnWeekLoad extends Animation {
  uiDidUpdate() {
    const action = this.acceptedAction('WEEK_LOADED')
    if (action.payload.initialWeeklyLoad) return
    const days = action.payload.weekDays
    this.focusFirstItem(days, true)
  }

  focusFirstItem = doFocusFirstItem.bind(this)
}

export class FocusFirstItemOnWeekJump extends Animation {
  uiDidUpdate() {
    const action = this.acceptedAction('JUMP_TO_WEEK')
    const days = action.payload.weekDays
    this.focusFirstItem(days)
  }

  focusFirstItem = doFocusFirstItem.bind(this)
}

function doFocusFirstItem(days) {
  const firstDayFirstItem = days[0]?.[1]?.[0]
  if (firstDayFirstItem) {
    const firstItem = this.manager().getRegistry().getComponent('item', firstDayFirstItem.uniqueId)
    if (firstItem?.component) {
      this.animator().scrollTo(
        firstItem.component.getScrollable(),
        this.manager().totalOffset(),
        () => {
          this.animator().focusElement(firstItem.component.getFocusable())
          const {associated_item, courseName, date, title} = {...firstItem.component.props}
          srAlert(
            formatMessage('{courseName} {type} due {date}', {
              courseName,
              date: getFriendlyDate(date),
              type: assignmentType(associated_item),
              title
            })
          )
        }
      )
    }
  } else {
    handleNothingToday(this.manager())
  }
}
