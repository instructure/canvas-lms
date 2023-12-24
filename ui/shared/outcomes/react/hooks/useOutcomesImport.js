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

import {useState, useCallback, useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import resolveProgress from '@canvas/progress/resolve_progress'
import {IMPORT_OUTCOMES} from '../../graphql/Management'
import {useMutation} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import useCanvasContext from './useCanvasContext'

const I18n = useI18nScope('FindOutcomesModal')

export const IMPORT_NOT_STARTED = 'IMPORT_NOT_STARTED'
export const IMPORT_PENDING = 'IMPORT_PENDING'
export const IMPORT_COMPLETED = 'IMPORT_COMPLETED'
export const IMPORT_FAILED = 'IMPORT_FAILED'
export const ROOT_GROUP = 'ROOT_GROUP'

const getLocalStorageActiveImports = () => {
  try {
    // if, for some reason, we have a bad activeImports data inside (like null string)
    // we won't break
    return JSON.parse(localStorage.activeImports || '[]') || []
  } catch (error) {
    return []
  }
}

const storeActiveImportsInLocalStorage = activeImports => {
  localStorage.activeImports = JSON.stringify(activeImports)
}

const useOutcomesImport = (outcomePollingInterval = 1000, groupPollingInterval = 5000) => {
  const [importGroupsStatus, setImportGroupsStatus] = useState({})
  const [importOutcomesStatus, setImportOutcomesStatus] = useState({})
  const {contextId: targetContextId, contextType: targetContextType, isCourse} = useCanvasContext()
  const [importOutcomesMutation] = useMutation(IMPORT_OUTCOMES)
  const [hasAddedOutcomes, setHasAddedOutcomes] = useState(false)

  const setStatus = useCallback(
    (outcomeOrGroupId, status, isGroup) => {
      if (isGroup) {
        setImportGroupsStatus(prevStatus => ({
          ...prevStatus,
          [outcomeOrGroupId]: status,
        }))
      } else {
        setImportOutcomesStatus(prevStatus => ({
          ...prevStatus,
          [outcomeOrGroupId]: status,
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
              message: err.message,
            })
          : I18n.t('An error occurred while importing this outcome: %{message}.', {
              message: err.message,
            })
        : isGroup
        ? I18n.t('An error occurred while importing these outcomes.')
        : I18n.t('An error occurred while importing this outcome.'),
      type: 'error',
    })

  const trackProgress = useCallback(
    async (progress, outcomeOrGroupId, isGroup, groupTitle, targetGroupTitle) => {
      const message = targetGroupTitle
        ? I18n.t(
            'All outcomes from %{groupTitle} have been successfully added to %{targetGroupTitle}.',
            {
              groupTitle,
              targetGroupTitle,
            }
          )
        : isCourse
        ? I18n.t('All outcomes from %{groupTitle} have been successfully added to this course.', {
            groupTitle,
          })
        : I18n.t('All outcomes from %{groupTitle} have been successfully added to this account.', {
            groupTitle,
          })
      try {
        await resolveProgress(
          {
            url: `/api/v1/progress/${progress._id}`,
            workflow_state: progress.state,
          },
          {
            interval: isGroup ? groupPollingInterval : outcomePollingInterval,
          }
        )
        const shouldShowAlert = getLocalStorageActiveImports().some(
          imp => imp.isGroup === isGroup && imp.outcomeOrGroupId === outcomeOrGroupId
        )
        if (isGroup && shouldShowAlert) {
          showFlashAlert({
            message,
            type: 'success',
          })
        }
        setStatus(outcomeOrGroupId, IMPORT_COMPLETED, isGroup)
      } catch (err) {
        showFlashError(err, isGroup)
        setStatus(outcomeOrGroupId, IMPORT_FAILED, isGroup)
      } finally {
        const activeImports = getLocalStorageActiveImports()
        storeActiveImportsInLocalStorage(
          activeImports.filter(
            imp => !(imp.isGroup === isGroup && imp.outcomeOrGroupId === outcomeOrGroupId)
          )
        )
      }
    },
    [isCourse, groupPollingInterval, outcomePollingInterval, setStatus]
  )

  useEffect(() => {
    getLocalStorageActiveImports().forEach(
      ({progress, outcomeOrGroupId, isGroup, groupTitle, targetGroupTitle}) => {
        setStatus(outcomeOrGroupId, IMPORT_PENDING, isGroup)
        trackProgress(progress, outcomeOrGroupId, isGroup, groupTitle, targetGroupTitle)
      }
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const importOutcomes = useCallback(
    async ({
      outcomeOrGroupId,
      sourceContextId,
      sourceContextType,
      targetGroupId,
      targetGroupTitle,
      groupTitle = null,
      isGroup = true,
    }) => {
      try {
        const input = targetGroupId
          ? {targetGroupId}
          : {
              targetContextId,
              targetContextType,
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

        const newTrackedImport = {
          outcomeOrGroupId,
          isGroup,
          groupTitle,
          targetGroupTitle,
          progress,
        }

        const activeImports = getLocalStorageActiveImports()
        activeImports.push(newTrackedImport)
        storeActiveImportsInLocalStorage(activeImports)
        trackProgress(progress, outcomeOrGroupId, isGroup, groupTitle, targetGroupTitle)
        setHasAddedOutcomes(true)
      } catch (err) {
        showFlashError(err, isGroup)
        setStatus(outcomeOrGroupId, IMPORT_FAILED, isGroup)
      }
    },
    [targetContextId, targetContextType, setStatus, importOutcomesMutation, trackProgress]
  )

  const clearGroupsStatus = () => setImportGroupsStatus({})

  const clearOutcomesStatus = () => setImportOutcomesStatus({})

  return {
    importOutcomes,
    importGroupsStatus,
    importOutcomesStatus,
    clearGroupsStatus,
    clearOutcomesStatus,
    hasAddedOutcomes,
    setHasAddedOutcomes,
  }
}

export default useOutcomesImport
