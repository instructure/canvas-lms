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

import {useState, useCallback} from 'react'
import {monitorProgress, type CanvasProgress} from '@canvas/progress/ProgressHelpers'
import {useMutation} from '@tanstack/react-query'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {calcPointsPossible} from '../utils'
import {mapRubricUnderscoredKeysToCamelCase} from '../../utils'
import type {RubricCriterion} from '../../types/rubric'
import type {GenerateCriteriaFormProps, RubricFormFieldSetter} from '../types/RubricForm'
import {regenerateCriteria} from '../queries/RubricFormQueries'

const I18n = createI18nScope('rubrics-form-regenerate-criteria')

type UseRegenerateCriteriaProps = {
  assignmentId?: string
  courseId?: string
  criteriaRef: React.MutableRefObject<RubricCriterion[]>
  generateOptions: Partial<GenerateCriteriaFormProps>
  setRubricFormField: RubricFormFieldSetter
}

export const useRegenerateCriteria = ({
  courseId,
  assignmentId,
  criteriaRef,
  generateOptions,
  setRubricFormField,
}: UseRegenerateCriteriaProps) => {
  const [regeneratedCriteriaProgress, setRegeneratedCriteriaProgress] = useState<CanvasProgress>()

  const onHandleProgressUpdates = useCallback(
    (progress: CanvasProgress) => {
      setRegeneratedCriteriaProgress(progress)
      if (progress.workflow_state === 'completed') {
        const transformed = mapRubricUnderscoredKeysToCamelCase(progress.results)
        const newCriteria = transformed.criteria ?? []

        // For regeneration, we replace the existing criteria with the new ones
        // The API should return the full set of criteria, not just the new ones
        const updatedCriteria = newCriteria.map(criterion => ({
          ...criterion,
          isGenerated: true,
        }))

        setRubricFormField('criteria', updatedCriteria)
        setRubricFormField('pointsPossible', calcPointsPossible(updatedCriteria))
      } else if (progress.workflow_state === 'failed') {
        showFlashError(I18n.t('Failed to regenerate criteria'))()
        return
      }
    },
    [setRubricFormField],
  )

  const updateProgress = (progress: CanvasProgress) => {
    setRegeneratedCriteriaProgress(progress)
    monitorProgress(progress.id, onHandleProgressUpdates, () => {
      showFlashError(I18n.t('Failed to regenerate criteria'))()
    })
  }

  const {
    isPending: regenerateCriteriaIsPending,
    isSuccess: regenerateCriteriaIsSuccess,
    isError: regenerateCriteriaIsError,
    mutate: regenerateCriteriaMutation,
  } = useMutation({
    mutationFn: ({
      criteriaForRegeneration,
      additionalPrompt,
      criterionId,
    }: {
      criteriaForRegeneration: RubricCriterion[]
      additionalPrompt: string
      criterionId?: string
    }) => {
      if (courseId && assignmentId) {
        return regenerateCriteria(
          courseId,
          assignmentId,
          criteriaForRegeneration,
          additionalPrompt,
          criterionId,
          generateOptions,
        )
      } else {
        throw new Error('Must be called from a course+assignment context')
      }
    },
    mutationKey: ['regenerate-criteria'],
    onSuccess: async successResponse => {
      const progress = successResponse as CanvasProgress
      updateProgress(progress)
    },
    onError: () => {
      showFlashError(I18n.t('Failed to regenerate criteria'))()
    },
  })

  const regenerateAllCriteria = useCallback(
    (additionalPrompt: string) => {
      const currentCriteria = criteriaRef.current
      regenerateCriteriaMutation({
        criteriaForRegeneration: currentCriteria,
        additionalPrompt,
      })
    },
    [criteriaRef, regenerateCriteriaMutation],
  )

  const regenerateSingleCriterion = useCallback(
    (criterion: RubricCriterion, additionalPrompt: string) => {
      const currentCriteria = criteriaRef.current
      regenerateCriteriaMutation({
        criteriaForRegeneration: currentCriteria,
        additionalPrompt,
        criterionId: criterion.id,
      })
    },
    [criteriaRef, regenerateCriteriaMutation],
  )

  return {
    regeneratedCriteriaProgress,
    regenerateCriteriaIsPending:
      regenerateCriteriaIsPending ||
      (regeneratedCriteriaProgress &&
        !['failed', 'completed'].includes(regeneratedCriteriaProgress.workflow_state)),
    regenerateCriteriaIsSuccess:
      regenerateCriteriaIsSuccess || regeneratedCriteriaProgress?.workflow_state === 'completed',
    regenerateCriteriaIsError:
      regenerateCriteriaIsError || regeneratedCriteriaProgress?.workflow_state === 'failed',
    regenerateAllCriteria,
    regenerateSingleCriterion,
  }
}
