/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {string} from 'prop-types'
import {Query} from 'react-apollo'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import {TEACHER_QUERY} from '../assignmentData'
import TeacherView from './TeacherView'

const I18n = useI18nScope('assignments_2')

TeacherQuery.propTypes = {
  assignmentLid: string,
  messageAttachmentUploadFolderId: string,
}

export default function TeacherQuery({assignmentLid, messageAttachmentUploadFolderId}) {
  return (
    <Query query={TEACHER_QUERY} variables={{assignmentLid}}>
      {({loading, error, data}) => {
        if (loading) {
          return (
            <View as="div" textAlign="center" padding="large 0">
              <Spinner size="large" renderTitle={I18n.t('Loading')} />
            </View>
          )
        } else if (error) {
          return <pre>Error: {JSON.stringify(error, null, 2)}</pre>
        }
        return (
          <TeacherView
            assignment={data.assignment}
            messageAttachmentUploadFolderId={messageAttachmentUploadFolderId}
          />
        )
      }}
    </Query>
  )
}
