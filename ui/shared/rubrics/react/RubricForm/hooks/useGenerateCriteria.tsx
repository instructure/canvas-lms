/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useState} from 'react'
import {monitorProgress, type CanvasProgress} from '@canvas/progress/ProgressHelpers'
import {useMutation} from '@tanstack/react-query'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('rubrics-form-generated-criteria')

type UseGenerateCriteriaProps = {
  generateCriteriaMutationFn?: () => Promise<CanvasProgress>
  handleProgressUpdates: (progress: CanvasProgress) => void
}
export const useGenerateCriteria = ({
  generateCriteriaMutationFn,
  handleProgressUpdates = () => {},
}: UseGenerateCriteriaProps) => {
  const [generatedCriteriaProgress, setGeneratedCriteriaProgress] = useState<CanvasProgress>()

  const updateProgress = (progress: CanvasProgress) => {
    setGeneratedCriteriaProgress(progress)
    monitorProgress(progress.id, handleProgressUpdates, () => {
      showFlashError(I18n.t('Failed to generate criteria'))()
    })
  }

  const {
    isPending: generateCriteriaIsPending,
    isSuccess: generateCriteriaIsSuccess,
    isError: generateCriteriaIsError,
    mutate: generateCriteriaMutation,
  } = useMutation({
    mutationFn: generateCriteriaMutationFn,
    mutationKey: ['generate-criteria'],
    onSuccess: async successResponse => {
      const progress = successResponse as CanvasProgress
      updateProgress(progress)
    },
    onError: () => {
      showFlashError(I18n.t('Failed to generate criteria'))()
    },
  })

  return {
    generatedCriteriaProgress,
    generateCriteriaMutation,
    generateCriteriaIsPending,
    generateCriteriaIsSuccess,
    generateCriteriaIsError,
  }
}
