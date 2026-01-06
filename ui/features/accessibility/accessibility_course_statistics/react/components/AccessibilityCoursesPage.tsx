/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Billboard} from '@instructure/ui-billboard'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useCourses} from '../../hooks/useCourses'
import {CoursesTable} from './CoursesTable'
import {AccessibilityGenericErrorPage} from './AccessibilityGenericErrorPage'
import EmptyDesert from '@canvas/images/react/EmptyDesert'
import type {CoursesResponse} from '../../types/course'

const I18n = createI18nScope('accessibility_course_statistics')

const getAccountId = (): string => {
  return window.ENV?.ACCOUNT_ID?.toString() || ''
}

const LoadingState: React.FC = () => (
  <View as="div" textAlign="center" padding="large">
    <Spinner renderTitle={I18n.t('Loading courses')} />
  </View>
)

const EmptyState: React.FC = () => (
  <Billboard
    size="large"
    heading={I18n.t('No courses found')}
    headingAs="h2"
    hero={<EmptyDesert />}
  />
)

const CoursesContent: React.FC<{
  isLoading: boolean
  isError: boolean
  data: CoursesResponse | undefined
}> = ({isLoading, isError, data}) => {
  if (isError) {
    return <AccessibilityGenericErrorPage />
  }

  if (isLoading && !data) {
    return <LoadingState />
  }

  if (!data || data.courses.length === 0) {
    return <EmptyState />
  }

  return <CoursesTable courses={data.courses} />
}

export const AccessibilityCoursesPage: React.FC = () => {
  const accountId = getAccountId()
  const {data, isLoading, isError} = useCourses({accountId})

  return (
    <View as="div">
      <Heading level="h1" margin="0 0 medium">
        {I18n.t('Accessibility report')}
      </Heading>

      <CoursesContent isLoading={isLoading} isError={isError} data={data} />
    </View>
  )
}
