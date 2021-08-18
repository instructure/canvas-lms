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

import {useState, useCallback} from 'react'
import I18n from 'i18n!FindOutcomesModal'
import resolveProgress from '@canvas/progress/resolve_progress'
import {IMPORT_OUTCOMES} from '@canvas/outcomes/graphql/Management'
import {useMutation} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

export const IMPORT_NOT_STARTED = 'IMPORT_NOT_STARTED'
export const IMPORT_PENDING = 'IMPORT_PENDING'
export const IMPORT_COMPLETED = 'IMPORT_COMPLETED'
export const IMPORT_FAILED = 'IMPORT_FAILED'

const useOutcomesImport = (outcomePollingInterval = 1000, groupPollingInterval = 5000) => {
  const [importGroupsStatus, setImportGroupsStatus] = useState({})
  const [importOutcomesStatus, setImportOutcomesStatus] = useState({})
  const {contextId: targetContextId, contextType: targetContextType, isCourse} = useCanvasContext()
  const [importOutcomesMutation] = useMutation(IMPORT_OUTCOMES)

  const setStatus = useCallback(
    (outcomeOrGroupId, status, isGroup) => {
      if (isGroup) {
        setImportGroupsStatus(prevStatus => ({
          ...prevStatus,
          [outcomeOrGroupId]: status
        }))
      } else {
        setImportOutcomesStatus(prevStatus => ({
          ...prevStatus,
          [outcomeOrGroupId]: status
        }))
      }
    },
    [setImportGroupsStatus, setImportOutcomesStatus]
  )

  const showFlashError = (err, isGroup) =>
    showFlashAlert({
      message: err.message
        ? isGroup
          ? I18n.t('An error occurred while importing these outcomes: %{message}.', {
              message: err.message
            })
          : I18n.t('An error occurred while importing this outcome: %{message}.', {
              message: err.message
            })
        : isGroup
        ? I18n.t('An error occurred while importing these outcomes.')
        : I18n.t('An error occurred while importing this outcome.'),
      type: 'error'
    })

  const trackProgress = useCallback(
    async (progress, outcomeOrGroupId, outcomesCount, isGroup) => {
      try {
        await resolveProgress(
          {
            url: `/api/v1/progress/${progress._id}`,
            workflow_state: progress.state
          },
          {
            interval: isGroup ? groupPollingInterval : outcomePollingInterval
          }
        )
        if (isGroup) {
          showFlashAlert({
            message: isCourse
              ? I18n.t(
                  {
                    one: '1 outcome has been successfully added to this course.',
                    other: '%{count} outcomes have been successfully added to this course.'
                  },
                  {
                    count: outcomesCount
                  }
                )
              : I18n.t(
                  {
                    one: '1 outcome has been successfully added to this account.',
                    other: '%{count} outcomes have been successfully added to this account.'
                  },
                  {
                    count: outcomesCount
                  }
                ),
            type: 'success'
          })
        }
        setStatus(outcomeOrGroupId, IMPORT_COMPLETED, isGroup)
      } catch (err) {
        showFlashError(err, isGroup)
        setStatus(outcomeOrGroupId, IMPORT_FAILED, isGroup)
      }
    },
    [groupPollingInterval, outcomePollingInterval, isCourse, setStatus]
  )

  const importOutcomes = useCallback(
    async (outcomeOrGroupId, outcomesCount, isGroup = true, sourceContextId, sourceContextType) => {
      try {
        const input = {
          targetContextId,
          targetContextType
        }
        if (isGroup) {
          input.groupId = outcomeOrGroupId
        } else {
          input.outcomeId = outcomeOrGroupId
          if (sourceContextId && sourceContextType) {
            input.sourceContextId = sourceContextId
            input.sourceContextType = sourceContextType
          }
        }

        setStatus(outcomeOrGroupId, IMPORT_PENDING, isGroup)
        const importResult = await importOutcomesMutation({variables: {input}})
        const progress = importResult.data?.importOutcomes?.progress
        const importErrors = importResult.data?.importOutcomes?.errors
        if (importErrors !== null) throw new Error(importErrors?.[0]?.message)

        trackProgress(progress, outcomeOrGroupId, outcomesCount, isGroup)
      } catch (err) {
        showFlashError(err, isGroup)
        setStatus(outcomeOrGroupId, IMPORT_FAILED, isGroup)
      }
    },
    [importOutcomesMutation, setStatus, trackProgress, targetContextId, targetContextType]
  )

  const clearGroupsStatus = () => setImportGroupsStatus({})

  const clearOutcomesStatus = () => setImportOutcomesStatus({})

  return {
    importOutcomes,
    importGroupsStatus,
    importOutcomesStatus,
    clearGroupsStatus,
    clearOutcomesStatus
  }
}

export default useOutcomesImport
