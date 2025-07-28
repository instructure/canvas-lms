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

import React, {useEffect, useState} from 'react'
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('profile')

enum ConfirmationState {
  HIDDEN = 'hidden',
  IDLE = 'idle',
  SENDING = 'sending',
  DONE = 'done',
  ERROR = 'error',
}

export const componentLabelByConfirmationState = {
  [ConfirmationState.HIDDEN]: null,
  [ConfirmationState.IDLE]: I18n.t('Re-Send Confirmation'),
  [ConfirmationState.SENDING]: I18n.t('Re-Sending...'),
  [ConfirmationState.DONE]: I18n.t('Done! Message may take a few minutes'),
  [ConfirmationState.ERROR]: I18n.t('Request failed. Try again'),
}

export interface ResendConfirmationProps {
  userId: string
  channelId: string
}

const ResendConfirmation = ({userId, channelId}: ResendConfirmationProps) => {
  const [confirmationState, setConfirmationState] = useState(ConfirmationState.HIDDEN)
  const componentLabel = componentLabelByConfirmationState[confirmationState]

  const sendConfirmation = async () => {
    setConfirmationState(ConfirmationState.SENDING)

    try {
      await doFetchApi({
        path: `/confirmations/${userId}/re_send/${channelId}`,
        method: 'POST',
      })

      setConfirmationState(ConfirmationState.DONE)
    } catch {
      setConfirmationState(ConfirmationState.ERROR)
    }
  }

  useEffect(() => {
    const checkIfConfirmationLimitIsReached = async () => {
      const {json} = await doFetchApi<{confirmation_limit_reached: boolean}>({
        path: `/confirmations/${userId}/limit_reached/${channelId}`,
      })

      if (!json?.confirmation_limit_reached) {
        setConfirmationState(ConfirmationState.IDLE)
      }
    }

    checkIfConfirmationLimitIsReached()
  }, [channelId, userId])

  return (
    componentLabel && (
      <Link width="fit-content" as="button" onClick={sendConfirmation} aria-label={componentLabel}>
        {componentLabel}
      </Link>
    )
  )
}

export default ResendConfirmation
