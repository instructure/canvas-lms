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
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import ErrorShip from '@canvas/images/ErrorShip.svg'
import {assignLocation} from '@canvas/util/globalUtils'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {createCourseCopyMutation} from '../mutations/createCourseCopyMutation'
import {coursesQuery} from '../queries/courseQuery'
import {useTermsQuery} from '../queries/termsQuery'
import {
  type CopyCourseFormSubmitData,
  courseCopyRootKey,
  courseFetchKey,
  createCourseAndMigrationKey,
} from '../types'
import {CopyCourseForm} from './form/CopyCourseForm'
import {useMutation, useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('content_copy_redesign')

export const onSuccessCallback = (newCourseId: string) => {
  window.location.href = `/courses/${newCourseId}/content_migrations`
}

export const onErrorCallback = () => {
  showFlashError(
    I18n.t('Something went wrong during copy course operation. Reload the page and try again.'),
  )()
}

export const CourseCopy = ({
  courseId,
  accountId,
  rootAccountId,
  userTimeZone,
  courseTimeZone,
  canImportAsNewQuizzes,
}: {
  courseId: string
  accountId: string
  rootAccountId: string
  userTimeZone?: string
  courseTimeZone?: string
  canImportAsNewQuizzes: boolean
}) => {
  const courseQueryResult = useQuery({
    queryKey: [courseCopyRootKey, courseFetchKey, courseId],
    queryFn: coursesQuery,
  })

  const termsQueryResult = useTermsQuery(rootAccountId)

  const mutation = useMutation({
    mutationKey: [courseCopyRootKey, createCourseAndMigrationKey, accountId],
    mutationFn: createCourseCopyMutation,
    onSuccess: onSuccessCallback,
    onError: onErrorCallback,
  })

  const handleCancel = () => {
    assignLocation(`/courses/${courseId}/settings`)
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
      userTimeZone={userTimeZone}
      courseTimeZone={courseTimeZone}
      isSubmitting={mutation.isPending || mutation.isSuccess}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  )
}

export default CourseCopy
