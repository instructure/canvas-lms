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
import GenericErrorPage from '@canvas/generic-error-page'
import TeacherCreateEditView from './TeacherCreateEditView'
import {TEACHER_EDIT_QUERY} from '@canvas/assignments/graphql/teacher/Queries'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {useQuery} from '@apollo/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

const I18n = createI18nScope('assignment_edit')

interface TeacherEditQueryProps {
  assignmentLid: string
}

const TeacherEditQuery: React.FC<TeacherEditQueryProps> = ({assignmentLid}) => {
  const {loading, error, data} = useQuery(TEACHER_EDIT_QUERY, {
    variables: {assignmentLid},
  })

  // @ts-expect-error
  const ErrorPage = ({error}) => {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Edit Assignments 2 Teacher initial query error')}
        errorCategory={I18n.t('Edit Assignments 2 Teacher Error Page')}
        errorMessage={error.message}
      />
    )
  }

  if (loading) {
    return (
      <View as="div" textAlign="center" padding="large 0">
        <Spinner size="large" renderTitle={I18n.t('Loading')} />
      </View>
    )
  }
  if (error) return <ErrorPage error={error} />

  // @ts-expect-error
  return <TeacherCreateEditView edit={true} assignment={data.assignment} />
}

export default TeacherEditQuery
