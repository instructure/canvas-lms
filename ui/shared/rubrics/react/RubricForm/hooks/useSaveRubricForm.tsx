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

import {useMutation} from '@tanstack/react-query'
import {RubricFormProps} from '../types/RubricForm'
import {queryClient} from '@canvas/query'
import {saveRubric} from '../queries/RubricFormQueries'
import {SaveRubricResponse} from 'features/rubrics/queries/RubricFormQueries'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('rubrics-form-save')

type UseSaveRubricFormProps = {
  accountId?: string
  assignmentId?: string
  courseId?: string
  queryKey: string[]
  rubricId?: string
  rubricForm: RubricFormProps
  handleSaveSuccess: (successResponse: SaveRubricResponse) => void
}
export const useSaveRubricForm = ({
  accountId,
  assignmentId,
  courseId,
  queryKey,
  rubricId,
  rubricForm,
  handleSaveSuccess,
}: UseSaveRubricFormProps) => {
  const {
    isPending: savePending,
    isSuccess: saveSuccess,
    isError: saveError,
    mutate: saveRubricMutation,
  } = useMutation({
    mutationFn: async () => saveRubric(rubricForm, assignmentId),
    mutationKey: ['save-rubric'],
    onSuccess: async successResponse => {
      showFlashSuccess(I18n.t('Rubric saved successfully'))()
      handleSaveSuccess(successResponse as SaveRubricResponse)
      const rubricsForContextQueryKey = accountId
        ? `accountRubrics-${accountId}`
        : `courseRubrics-${courseId}`
      await queryClient.invalidateQueries({queryKey}, {cancelRefetch: true})
      await queryClient.invalidateQueries(
        {queryKey: [rubricsForContextQueryKey]},
        {
          cancelRefetch: true,
        },
      )
      await queryClient.invalidateQueries(
        {queryKey: [`rubric-preview-${rubricId}`]},
        {cancelRefetch: true},
      )
    },
  })

  return {
    savePending,
    saveSuccess,
    saveError,
    saveRubricMutation,
  }
}
