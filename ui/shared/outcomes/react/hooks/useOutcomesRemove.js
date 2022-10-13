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

import {useState, useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {DELETE_OUTCOME_LINKS} from '../../graphql/Management'
import {useMutation} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('OutcomeManagement')

export const REMOVE_NOT_STARTED = 'REMOVE_NOT_STARTED'
export const REMOVE_PENDING = 'REMOVE_PENDING'
export const REMOVE_COMPLETED = 'REMOVE_COMPLETED'
export const REMOVE_FAILED = 'REMOVE_FAILED'

const useOutcomesRemove = () => {
  const [deleteOutcomeLinks] = useMutation(DELETE_OUTCOME_LINKS)
  const [removeOutcomesStatus, setRemoveOutcomesStatus] = useState({})

  const setStatus = (outcomeId, status) => {
    setRemoveOutcomesStatus(prevStatus => ({
      ...prevStatus,
      [outcomeId]: status,
    }))
  }

  const showFlashMessage = (outcomeCount, success = false) => {
    if (success) {
      showFlashAlert({
        message: I18n.t(
          {
            one: 'This outcome was successfully removed.',
            other: '%{count} outcomes were successfully removed.',
          },
          {
            count: outcomeCount,
          }
        ),
        type: 'success',
      })
    } else {
      showFlashAlert({
        message: I18n.t(
          {
            one: 'An error occurred while removing this outcome. Please try again.',
            other: 'An error occurred while removing these outcomes. Please try again.',
          },
          {
            count: outcomeCount,
          }
        ),
        type: 'error',
      })
    }
  }

  const removeOutcomes = useCallback(
    async outcomes => {
      const removableLinkIds = Object.keys(outcomes).filter(linkId => outcomes[linkId].canUnlink)
      const nonRemovableLinkIds = Object.keys(outcomes).filter(
        linkId => !outcomes[linkId].canUnlink
      )
      const removableCount = removableLinkIds.length
      const nonRemovableCount = nonRemovableLinkIds.length
      const totalCount = removableCount + nonRemovableCount

      try {
        removableLinkIds.forEach(linkId => {
          setStatus(linkId, REMOVE_PENDING)
        })
        const result = await deleteOutcomeLinks({
          variables: {
            input: {
              ids: removableLinkIds,
            },
          },
        })

        const deletedOutcomeLinkIds = result.data?.deleteOutcomeLinks?.deletedOutcomeLinkIds
        const errorMessage = result.data?.deleteOutcomeLinks?.errors?.[0]?.errorMessage
        if (deletedOutcomeLinkIds?.length === 0) throw new Error(errorMessage)
        if (deletedOutcomeLinkIds?.length !== removableCount) throw new Error()

        if (deletedOutcomeLinkIds) {
          deletedOutcomeLinkIds.forEach(linkId => {
            setStatus(linkId, REMOVE_COMPLETED)
          })
        }
        showFlashMessage(totalCount, true)
      } catch (err) {
        removableLinkIds.forEach(linkId => {
          setStatus(linkId, REMOVE_FAILED)
        })
        showFlashMessage(totalCount)
      }
    },
    [deleteOutcomeLinks]
  )

  return {
    removeOutcomes,
    removeOutcomesStatus,
    setRemoveOutcomesStatus,
  }
}

export default useOutcomesRemove
