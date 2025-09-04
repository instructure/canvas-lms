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

import {useCallback, useState} from 'react'
import {monitorProgress, type CanvasProgress} from '@canvas/progress/ProgressHelpers'
import {useMutation} from '@tanstack/react-query'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {GenerateCriteriaFormProps, RubricFormFieldSetter} from '../types/RubricForm'
import {generateCriteria} from '../queries/RubricFormQueries'
import {mapRubricUnderscoredKeysToCamelCase} from '../../utils'
import {calcPointsPossible} from '../utils'
import {RubricCriterion} from '../../types/rubric'

const I18n = createI18nScope('rubrics-form-generated-criteria')

type UseGenerateCriteriaProps = {
  courseId?: string
  assignmentId?: string
  generateOptions: GenerateCriteriaFormProps
  criteriaRef: React.MutableRefObject<RubricCriterion[]>
  setRubricFormField: RubricFormFieldSetter
}
export const useGenerateCriteria = ({
  courseId,
  criteriaRef,
  generateOptions,
  assignmentId,
  setRubricFormField,
}: UseGenerateCriteriaProps) => {
  const [generateCriteriaProgress, setGenerateCriteriaProgress] = useState<CanvasProgress>()

  const handleProgressUpdates = useCallback(
    (progress: CanvasProgress) => {
      setGenerateCriteriaProgress(progress)

      if (progress.workflow_state === 'failed') {
        showFlashError(I18n.t('Failed to generate criteria'))()
        return
      }

      if (progress.workflow_state === 'completed') {
        const transformed = mapRubricUnderscoredKeysToCamelCase(progress.results)
        const criteria = transformed.criteria ?? []
        const newCriteria = [
          ...criteriaRef.current,
          ...criteria.map(criterion => ({
            ...criterion,
            isGenerated: true,
          })),
        ]

        setRubricFormField('criteria', newCriteria)
        setRubricFormField('pointsPossible', calcPointsPossible(newCriteria))
      }
    },
    [criteriaRef, setRubricFormField],
  )

  const updateProgress = (progress: CanvasProgress) => {
    handleProgressUpdates(progress)
    monitorProgress(progress.id, handleProgressUpdates, () => {
      showFlashError(I18n.t('Failed to generate criteria'))()
    })
  }

  const generateCriteriaMutationFn = () => {
    if (!courseId || !assignmentId) {
      throw new Error('Must be called from a course+assignment context')
    }

    return generateCriteria(courseId, assignmentId, generateOptions)
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
    generateCriteriaProgress,
    generateCriteriaIsPending:
      generateCriteriaIsPending ||
      (generateCriteriaProgress?.workflow_state &&
        !['completed', 'failed'].includes(generateCriteriaProgress.workflow_state)),
    generateCriteriaIsSuccess:
      generateCriteriaIsSuccess && generateCriteriaProgress?.workflow_state === 'completed',
    generateCriteriaIsError:
      generateCriteriaIsError || generateCriteriaProgress?.workflow_state === 'failed',
    generateCriteriaMutation,
  }
}
