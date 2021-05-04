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

import I18n from 'i18n!OutcomeManagement'
import {moveOutcome} from '@canvas/outcomes/graphql/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const startMoveOutcome = async (
  contextType,
  contextId,
  selectedOutcome,
  oldParentGroupId,
  newParentGroup
) => {
  try {
    await moveOutcome(
      contextType,
      contextId,
      selectedOutcome._id,
      oldParentGroupId,
      newParentGroup.id
    )
    showFlashAlert({
      message: I18n.t('"%{title}" has been moved to "%{newGroupTitle}".', {
        title: selectedOutcome.title,
        newGroupTitle: newParentGroup.name
      }),
      type: 'success'
    })
  } catch (err) {
    showFlashAlert({
      message: err.message
        ? I18n.t('An error occurred moving outcome "%{title}": %{message}', {
            title: selectedOutcome.title,
            message: err.message
          })
        : I18n.t('An error occurred moving outcome "%{title}"', {
            title: selectedOutcome.title
          }),
      type: 'error'
    })
  }
}

export default startMoveOutcome
