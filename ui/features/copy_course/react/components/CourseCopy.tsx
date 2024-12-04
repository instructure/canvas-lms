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

import React from 'react'
import {CopyCourseForm} from './form/CopyCourseForm'
import {useQuery, useMutation} from '@canvas/query'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {coursesQuery} from '../queries/courseQuery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useTermsQuery} from '../queries/termsQuery'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {
  type CopyCourseFormSubmitData,
  courseCopyRootKey,
  courseFetchKey,
  createCourseAndMigrationKey,
} from '../types'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {createCourseCopyMutation} from '../mutations/createCourseCopyMutation'
// @ts-ignore
import ErrorShip from '@canvas/images/ErrorShip.svg'

const I18n = useI18nScope('content_copy_redesign')

export const onSuccessCallback = (newCourseId: string) => {
  window.location.href = `/courses/${newCourseId}/content_migrations`
}

export const onErrorCallback = () => {
  showFlashError(
    I18n.t('Something went wrong during copy course operation. Reload the page and try again.')
  )()
}

export const CourseCopy = ({
  courseId,
  accountId,
  timeZone,
  canImportAsNewQuizzes,
}: {
  courseId: string
  accountId: string
  timeZone?: string
  canImportAsNewQuizzes: boolean
}) => {
  const courseQueryResult = useQuery({
    queryKey: [courseCopyRootKey, courseFetchKey, courseId],
    queryFn: coursesQuery,
    meta: {fetchAtLeastOnce: true},
  })

  const termsQueryResult = useTermsQuery(accountId)

  const mutation = useMutation({
    mutationKey: [courseCopyRootKey, createCourseAndMigrationKey, accountId],
    mutationFn: createCourseCopyMutation,
    onSuccess: onSuccessCallback,
    onError: onErrorCallback,
  })

  const handleCancel = () => {
    window.location.href = `/courses/${courseId}/settings`
  }

  const handleSubmit = (formData: CopyCourseFormSubmitData) => {
    mutation.mutate({accountId, formData, courseId})
  }

  if (
    courseQueryResult.isLoading ||
    termsQueryResult.isLoading ||
    (!termsQueryResult.isError && termsQueryResult.hasNextPage !== false)
  ) {
    return (
      <Flex height="80vh" justifyItems="center" padding="large">
        <Flex.Item textAlign="center">
          <Spinner renderTitle={() => I18n.t('Course copy page is loading')} size="large" />
        </Flex.Item>
      </Flex>
    )
  }

  if (
    courseQueryResult.isError ||
    !courseQueryResult.data ||
    termsQueryResult.isError ||
    !termsQueryResult.data
  ) {
    return (
      <GenericErrorPage
        imageUrl={ErrorShip}
        errorSubject={I18n.t('Page loading error')}
        errorCategory={I18n.t('Course Copy Error Page')}
        errorMessage={I18n.t('Try to reload the page.')}
      />
    )
  }

  return (
    <CopyCourseForm
      canImportAsNewQuizzes={canImportAsNewQuizzes}
      course={courseQueryResult.data}
      terms={termsQueryResult.data}
      timeZone={timeZone}
      isSubmitting={mutation.isLoading || mutation.isSuccess}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  )
}

export default CourseCopy
