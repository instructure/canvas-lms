/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Button} from '@instructure/ui-buttons'
import {IconAlertsSolid} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import axios from '@canvas/axios'

const I18n = useI18nScope('grade_summary')
type ClearBadgeCountsButtonProps = {
  userId: string
  courseId: string
}

function ClearBadgeCountsButton({courseId, userId}: ClearBadgeCountsButtonProps) {
  const [interaction, setInteraction] = useState<'enabled' | 'disabled' | 'readonly' | undefined>(
    'enabled'
  )
  const handleClick = async () => {
    setInteraction('disabled')
    const url = `/api/v1/courses/${courseId}/submissions/${userId}/clear_unread`
    try {
      const res = await axios.put(url)
      if (res.status === 204) {
        const successMessage = 'Badge counts cleared!'
        showFlashSuccess(successMessage)()
      } else {
        throw new Error(`Request failed with status code ${res.status}`)
      }
    } catch (e) {
      const errorMessage = 'Error clearing badge counts.'
      showFlashError(errorMessage)(e as Error)
    }
  }

  return (
    <Button
      data-testid="clear-badge-counts-button"
      color="primary"
      margin="small"
      onClick={handleClick}
      renderIcon={IconAlertsSolid}
      interaction={interaction}
    >
      {I18n.t('Clear Badge Counts')}
    </Button>
  )
}

export default ClearBadgeCountsButton
