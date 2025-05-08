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

import React, {useState} from 'react'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useMutation} from '@tanstack/react-query'
import {ImportRubricTray} from './ImportRubricTray'
import {ImportFailuresModal} from './ImportFailuresModal'
// @ts-expect-error
import type {RubricImport} from '../../../types/Rubric'
import {
  fetchRubricImport,
  getImportedRubrics,
  importRubric,
} from '../../../queries/ViewRubricQueries'
import type {Rubric} from '@canvas/rubrics/react/types/rubric'

const I18n = createI18nScope('rubrics-import')

export type ImportRubricProps = {
  isTrayOpen: boolean
  accountId?: string
  courseId?: string
  importFetchInterval?: number
  handleTrayClose: () => void
  handleImportSuccess: (importedRubrics: Rubric[]) => Promise<void>
}
export const ImportRubric = ({
  accountId,
  courseId,
  isTrayOpen: importTrayIsOpen,
  importFetchInterval = 1000,
  handleTrayClose: handleCloseImportTray,
  handleImportSuccess,
}: ImportRubricProps) => {
  const [currentImports, setCurrentImports] = useState<RubricImport[]>([])
  const [importErrorModalOpen, setImportErrorModalOpen] = useState(false)
  const [failedImports, setFailedImports] = useState<RubricImport[]>([])
  const [importFile, setImportFile] = useState<File | undefined>()

  const {mutate: importFileMutate} = useMutation({
    mutationFn: async (): Promise<RubricImport> => importRubric(importFile, accountId, courseId),
    mutationKey: ['import-rubric'],
    onSuccess: async data => {
      showFlashSuccess(I18n.t('Rubric import started. This may take a few seconds to complete.'))()
      const importResponse = data as RubricImport
      setCurrentImports(prevState => [...prevState, importResponse])
      checkImportStatus(importResponse.id)
    },
    onError: () => {
      showFlashError(I18n.t('Error Importing rubric'))()
    },
  })

  const onImport = async (file: File) => {
    setImportFile(file)
    importFileMutate()
  }

  const checkImportStatus = (importId?: string) => {
    const intervalId = setInterval(async () => {
      try {
        const currentImport = await fetchRubricImport(importId, accountId, courseId)
        const workflowState = currentImport.workflowState

        if (!currentImport?.id) {
          clearInterval(intervalId)
          return
        }

        setCurrentImports(prevState => {
          const importIndex = prevState.findIndex(importItem => importItem.id === currentImport.id)
          if (importIndex === -1) {
            return prevState
          }
          prevState[importIndex] = currentImport
          return [...prevState]
        })

        if (
          workflowState === 'succeeded' ||
          workflowState === 'succeeded_with_errors' ||
          workflowState === 'failed'
        ) {
          clearInterval(intervalId)

          if (workflowState === 'succeeded') {
            const importedRubrics = await getImportedRubrics(currentImport.id, accountId, courseId)
            const newRubricCount = importedRubrics.length
            await handleImportSuccess(importedRubrics)
            const successMessage = I18n.t(
              {
                zero: 'No rubrics were successfully imported',
                one: '1 rubric was successfully imported',
                other: '%{count} rubrics were successfully imported',
              },
              {
                count: newRubricCount ?? 0,
              },
            )
            showFlashSuccess(successMessage)()
          } else if (workflowState === 'succeeded_with_errors') {
            const importedRubrics = await getImportedRubrics(currentImport.id, accountId, courseId)
            await handleImportSuccess(importedRubrics)
            setFailedImports(prevState => [...prevState, currentImport])
            setImportErrorModalOpen(true)
          } else {
            const errorMessage =
              currentImport.errorData[0]?.message || I18n.t('Unknown error occurred')
            showFlashError(errorMessage)()
            setFailedImports(prevState => [...prevState, currentImport])
            setImportErrorModalOpen(true)
          }
        }
      } catch (error) {
        clearInterval(intervalId)
        showFlashError(I18n.t('Error retrieving import status'))()
      }
    }, importFetchInterval)
  }

  const handleOnClickImport = (rubricImport: RubricImport) => {
    const failedStates = ['failed', 'succeeded_with_errors']
    if (failedStates.includes(rubricImport.workflowState)) {
      setImportErrorModalOpen(true)
    }
  }

  return (
    <>
      <ImportRubricTray
        currentImports={currentImports}
        isOpen={importTrayIsOpen}
        onClickImport={handleOnClickImport}
        onClose={handleCloseImportTray}
        onImport={onImport}
      />
      <ImportFailuresModal
        rubricImports={failedImports}
        isOpen={importErrorModalOpen}
        onDismiss={() => setImportErrorModalOpen(false)}
      />
    </>
  )
}
