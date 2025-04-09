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
import {useScope as createI18nScope} from '@canvas/i18n'
import {RubricAssessmentImportTray} from './RubricAssessmentImportTray'
import {useMutation} from '@tanstack/react-query'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {
  type RubricAssessmentImportResponse,
  importRubricAssessment,
  fetchRubricAssessmentImport,
} from '../queries/Queries'
import useStore from '../stores'
import {RubircAssessmentImportFailuresModal} from './RubricAssessmentImportFailuresModal'

const I18n = createI18nScope('rubrics-import')

export const RubricAssessmentImport = () => {
  const [importFile, setImportFile] = useState<File | undefined>()
  const [currentImports, setCurrentImports] = useState<RubricAssessmentImportResponse[]>([])
  const [importErrorModalOpen, setImportErrorModalOpen] = useState(false)
  const [failedImports, setFailedImports] = useState<RubricAssessmentImportResponse[]>([])

  const checkImportStatus = (importId?: string) => {
    const intervalId = setInterval(async () => {
      try {
        const currentImport = await fetchRubricAssessmentImport(
          importId,
          assignment?.courseId,
          assignment?.id,
        )
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
            const successMessage = I18n.t('rubrics assessments were successfully imported')
            showFlashSuccess(successMessage)()
          } else if (workflowState === 'succeeded_with_errors') {
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
      } catch (_e) {
        clearInterval(intervalId)
        showFlashError(I18n.t('Error retrieving import status'))()
      }
    }, 1000)
  }

  const handleOnClickImport = (rubricImport: RubricAssessmentImportResponse) => {
    const failedStates = ['failed', 'succeeded_with_errors']
    if (failedStates.includes(rubricImport.workflowState)) {
      setImportErrorModalOpen(true)
    }
  }

  const {rubricAssessmentImportTrayProps} = useStore()

  const {assignment} = rubricAssessmentImportTrayProps

  const {mutate: importFileMutate} = useMutation({
    mutationFn: async (): Promise<RubricAssessmentImportResponse> =>
      importRubricAssessment(importFile, assignment?.courseId, assignment?.id),
    mutationKey: ['import-rubric-assessment'],
    onSuccess: async (data: RubricAssessmentImportResponse) => {
      showFlashSuccess(I18n.t('Rubric import started. This may take a few seconds to complete.'))()
      setCurrentImports(prevState => [...prevState, data])
      checkImportStatus(data.id)
    },
    onError: () => {
      showFlashError(I18n.t('Error Importing rubric'))()
    },
  })

  const onImport = async (file: File) => {
    setImportFile(file)
    importFileMutate()
  }

  return (
    <>
      <RubricAssessmentImportTray
        currentImports={currentImports}
        onClickImport={handleOnClickImport}
        onImport={onImport}
      />
      <RubircAssessmentImportFailuresModal
        rubricImports={failedImports}
        isOpen={importErrorModalOpen}
        onDismiss={() => setImportErrorModalOpen(false)}
      />
    </>
  )
}
